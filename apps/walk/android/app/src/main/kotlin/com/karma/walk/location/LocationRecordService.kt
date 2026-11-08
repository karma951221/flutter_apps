package com.karma.walk.location

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.util.Log
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.CancellationTokenSource
import com.karma.walk.MainActivity
import com.karma.walk.R
import com.karma.walk.location.LocationRecordRules.Action
import com.karma.walk.location.LocationRecordRules.Phase
import java.util.concurrent.Executor

/**
 * 상시 위치 기록 포그라운드 서비스(type `location`). 받은 점은 [LocationInbox] 에 바로 쓴다 —
 * Flutter 엔진 없이 돈다. 요청 값 · 정지 감지 규칙은 [LocationRecordRules].
 *
 * - 시작: 채널 `start` · 부팅 리시버가 `startForegroundService(ACTION_START)`, 시스템이 죽였다 다시
 *   띄우면(START_STICKY) 인텐트 없이 온다 — 어느 쪽이든 prefs 의 모드로 기록한다.
 * - 정지 감지(평소 + 활동 인식 권한): `STILL` 진입이면 한 점을 `still` 로 남기고 위치 요청을 멈추고,
 *   이탈이면 요청을 다시 걸고 한 점을 잡는다. 단계는 prefs 에 둬서 재시작 뒤에도 이어 간다.
 * - 백그라운드 위치 권한이 사라지면 멈추고 끝난다. prefs 의 켜짐은 그대로라 `status` 는 `blocked`.
 */
class LocationRecordService : Service() {
    companion object {
        private const val TAG = "LocationRecord"
        const val ACTION_START = "com.karma.walk.location.START"
        const val ACTION_STOP = "com.karma.walk.location.STOP"
        const val ACTION_SET_MODE = "com.karma.walk.location.SET_MODE"
        const val ACTION_TRANSITION = "com.karma.walk.location.TRANSITION"
        const val EXTRA_ENTERED_STILL = "enteredStill"

        private const val CHANNEL_ID = "location_record"
        private const val NOTIFICATION_ID = 5_000_003
        private const val TRANSITION_REQUEST_CODE = 5_000_003

        /** 이 프로세스에서 서비스가 떠 있는지. 채널 `setMode` · 전환 리시버가 본다. */
        @Volatile
        var running: Boolean = false
            private set

        /** 앱이 앞에 있을 때 · 부팅 직후 부른다. 권한 확인은 부르는 쪽이 한다. */
        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context,
                Intent(context, LocationRecordService::class.java).setAction(ACTION_START),
            )
        }

        /** 이미 떠 있는 서비스에 일을 보낸다(앱이 포그라운드 서비스를 가져 시작 제한이 없다). */
        fun send(context: Context, action: String, extras: Intent.() -> Unit = {}) {
            val intent = Intent(context, LocationRecordService::class.java).setAction(action).apply(extras)
            context.startService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, LocationRecordService::class.java))
        }

        /** 10 미만은 위치 권한이 곧 백그라운드 권한이다. */
        fun hasBackgroundPermission(context: Context): Boolean {
            val foreground = granted(context, Manifest.permission.ACCESS_FINE_LOCATION) ||
                granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return foreground
            return foreground && granted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }

        /** 10 미만은 Play Services 의 설치 권한이라 늘 있다. */
        fun hasActivityRecognition(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
            return granted(context, Manifest.permission.ACTIVITY_RECOGNITION)
        }

        fun isLocationOn(context: Context): Boolean {
            val manager = context.getSystemService(LocationManager::class.java) ?: return false
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                manager.isLocationEnabled
            } else {
                manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                    manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
            }
        }

        private fun granted(context: Context, permission: String): Boolean =
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    private lateinit var fused: FusedLocationProviderClient
    private lateinit var worker: HandlerThread
    private lateinit var handler: Handler
    private lateinit var executor: Executor

    private lateinit var mainExecutor: Executor

    // 상태는 메인 스레드에서만 바꾼다(Task 리스너도 mainExecutor). 점 저장 · 위치 콜백은 worker 스레드라
    // 읽는 값에 @Volatile 을 붙인다.
    @Volatile
    private var mode: String = LocationRecordRules.MODE_NORMAL

    @Volatile
    private var updating = false

    /** 전환 구독이 성공으로 확인됐는지. 요청 중이거나 실패하면 false. */
    @Volatile
    private var transitionsOn = false

    /** 구독 요청 · 해제마다 올린다. 늦게 온 옛 요청의 결과를 버린다. */
    private var transitionGen = 0
    private var transitionsPending = false

    @Volatile
    private var destroyed = false

    private val callback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            for (location in result.locations) save(location, still = false)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        fused = LocationServices.getFusedLocationProviderClient(this)
        worker = HandlerThread("location-record").also { it.start() }
        handler = Handler(worker.looper)
        executor = Executor { handler.post(it) }
        mainExecutor = ContextCompat.getMainExecutor(this)
        // 새 인스턴스는 움직이는 중으로 시작한다 — 죽어 있던 사이의 전환은 버려졌다. 다시 멈추는 건
        // 새 STILL 진입이 한다.
        LocationRecordPrefs.setPhase(
            this,
            LocationRecordRules.phaseOnServiceStart(newInstance = true, saved = LocationRecordPrefs.phase(this)),
        )
        running = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                // 알림의 [끄기]: 확인 없이 바로 끈다(다시 켜기 쉬움).
                LocationRecordPrefs.setEnabled(this, false)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_TRANSITION -> {
                if (!ensureForeground()) return START_NOT_STICKY
                onTransition(intent.getBooleanExtra(EXTRA_ENTERED_STILL, false))
            }
            ACTION_SET_MODE -> {
                if (!ensureForeground()) return START_NOT_STICKY
                apply()
            }
            // ACTION_START · START_STICKY 재시작(intent == null)
            else -> {
                if (!ensureForeground()) return START_NOT_STICKY
                apply()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        destroyed = true
        running = false
        stopUpdates()
        stopTransitions()
        worker.quitSafely()
        super.onDestroy()
    }

    /**
     * 켜짐 · 권한을 확인하고 포그라운드로 올린다. `startForegroundService` 로 왔으면 바로 불러야 한다.
     * 꺼졌거나 권한이 없으면 끝낸다(켜짐은 그대로 → `blocked`).
     */
    private fun ensureForeground(): Boolean {
        mode = LocationRecordPrefs.mode(this)
        val allowed = LocationRecordPrefs.enabled(this) && hasBackgroundPermission(this)
        if (allowed) {
            try {
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                } else {
                    0
                }
                ServiceCompat.startForeground(this, NOTIFICATION_ID, notification(), type)
                return true
            } catch (e: Exception) {
                // Android 12+ 백그라운드 시작 제한 · 14+ 위치 권한 확인 실패.
                Log.w(TAG, "startForeground failed", e)
            }
        }
        stopUpdates()
        stopTransitions()
        stopSelf()
        return false
    }

    /** prefs 의 모드 · 단계대로 위치 요청과 전환 구독을 맞춘다. */
    private fun apply() {
        val stillDetection = stillDetection()
        if (stillDetection) startTransitions() else stopTransitions()
        if (!stillDetection) LocationRecordPrefs.setPhase(this, Phase.MOVING)
        stopUpdates()
        if (LocationRecordPrefs.phase(this) == Phase.MOVING) startUpdates()
    }

    /** 정지 감지를 쓰려는지(평소 + 활동 인식 권한). 구독 성공 여부는 [transitionsOn]. */
    private fun stillDetection(): Boolean =
        mode == LocationRecordRules.MODE_NORMAL && hasActivityRecognition(this)

    private fun onTransition(enteredStill: Boolean) {
        val (next, action) = LocationRecordRules.onTransition(
            mode,
            LocationRecordPrefs.phase(this),
            enteredStill,
            stillDetection() && transitionsOn,
        )
        LocationRecordPrefs.setPhase(this, next)
        when (action) {
            Action.Pause -> {
                stopUpdates()
                fixOnce(still = true)
            }
            Action.ResumeAndFix -> {
                startUpdates()
                fixOnce(still = false)
            }
            Action.None -> Unit
        }
    }

    @SuppressLint("MissingPermission")
    private fun startUpdates() {
        if (updating) return
        val rules = LocationRecordRules.requestFor(mode)
        val request = LocationRequest.Builder(rules.priority, rules.intervalMs)
            .setMinUpdateDistanceMeters(rules.minDistanceM)
            .setMaxUpdateDelayMillis(rules.maxDelayMs)
            .build()
        try {
            updating = true
            fused.requestLocationUpdates(request, callback, worker.looper)
                .addOnFailureListener(mainExecutor) { e ->
                    Log.w(TAG, "location updates failed", e)
                    if (destroyed) return@addOnFailureListener
                    fused.removeLocationUpdates(callback)
                    updating = false
                    if (e is SecurityException) onPermissionLost(e)
                }
        } catch (e: SecurityException) {
            updating = false
            onPermissionLost(e)
        }
    }

    private fun stopUpdates() {
        if (!updating) return
        fused.removeLocationUpdates(callback)
        updating = false
    }

    /** 지금 위치 한 점. 못 잡으면 5분 안의 마지막 위치로 대신하고, 그것도 없으면 건너뛴다. */
    @SuppressLint("MissingPermission")
    private fun fixOnce(still: Boolean) {
        val priority = LocationRecordRules.requestFor(mode).priority
        try {
            fused.getCurrentLocation(priority, CancellationTokenSource().token)
                .addOnSuccessListener(mainExecutor) { location ->
                    if (destroyed) return@addOnSuccessListener
                    if (location != null) {
                        saveAsync(location, still)
                    } else {
                        lastKnown(still)
                    }
                }
                .addOnFailureListener(mainExecutor) { e ->
                    Log.w(TAG, "current location failed", e)
                    if (!destroyed) lastKnown(still)
                }
        } catch (e: SecurityException) {
            onPermissionLost(e)
        }
    }

    @SuppressLint("MissingPermission")
    private fun lastKnown(still: Boolean) {
        try {
            fused.lastLocation
                .addOnSuccessListener(mainExecutor) { location ->
                    if (destroyed) return@addOnSuccessListener
                    when {
                        location == null -> Log.w(TAG, "no fix: current and last location both empty")
                        LocationRecordRules.isFreshFallback(location.time, System.currentTimeMillis()) ->
                            saveAsync(location, still)
                        else -> Log.w(TAG, "no fix: last location older than 5 minutes, skipped")
                    }
                }
                .addOnFailureListener(mainExecutor) { e ->
                    Log.w(TAG, "no fix: current and last location both failed", e)
                }
        } catch (e: SecurityException) {
            onPermissionLost(e)
        }
    }

    /** inbox 쓰기는 worker 스레드에서. */
    private fun saveAsync(location: Location, still: Boolean) {
        executor.execute { save(location, still) }
    }

    private fun save(location: Location, still: Boolean) {
        try {
            LocationInbox.get(this).insert(
                t = location.time,
                lat = location.latitude,
                lng = location.longitude,
                acc = if (location.hasAccuracy()) location.accuracy.toDouble() else null,
                mode = mode,
                still = still,
            )
        } catch (e: Exception) {
            Log.w(TAG, "inbox insert failed", e)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startTransitions() {
        if (transitionsOn || transitionsPending) return
        val request = ActivityTransitionRequest(
            listOf(
                ActivityTransition.Builder()
                    .setActivityType(DetectedActivity.STILL)
                    .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
                    .build(),
                ActivityTransition.Builder()
                    .setActivityType(DetectedActivity.STILL)
                    .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_EXIT)
                    .build(),
            ),
        )
        val gen = ++transitionGen
        transitionsPending = true
        try {
            ActivityRecognition.getClient(this)
                .requestActivityTransitionUpdates(request, transitionIntent())
                .addOnSuccessListener(mainExecutor) {
                    if (destroyed || gen != transitionGen) return@addOnSuccessListener
                    transitionsPending = false
                    transitionsOn = true
                }
                .addOnFailureListener(mainExecutor) { e ->
                    Log.w(TAG, "transition updates failed", e)
                    if (destroyed || gen != transitionGen) return@addOnFailureListener
                    onTransitionsFailed()
                }
        } catch (e: SecurityException) {
            Log.w(TAG, "activity recognition denied", e)
            onTransitionsFailed()
        }
    }

    /** 정지 감지 없이 평소 간격으로 돈다 — 멈춰 있었다면 요청을 다시 건다. */
    private fun onTransitionsFailed() {
        transitionsPending = false
        transitionsOn = false
        LocationRecordPrefs.setPhase(this, Phase.MOVING)
        startUpdates()
    }

    /** 이전 서비스 인스턴스가 건 구독도 지우도록 늘 해제를 보낸다(같은 PendingIntent 라 멱등). */
    @SuppressLint("MissingPermission")
    private fun stopTransitions() {
        transitionGen++
        transitionsPending = false
        try {
            ActivityRecognition.getClient(this).removeActivityTransitionUpdates(transitionIntent())
        } catch (e: SecurityException) {
            Log.w(TAG, "activity recognition denied", e)
        }
        transitionsOn = false
    }

    /** Play Services 가 결과를 채워 넣어야 해서 mutable(Android 12+). 대상은 명시적 리시버. */
    private fun transitionIntent(): PendingIntent {
        val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        return PendingIntent.getBroadcast(
            this,
            TRANSITION_REQUEST_CODE,
            Intent(this, ActivityTransitionReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or mutable,
        )
    }

    /** 메인 스레드에서만 불린다(동기 호출 · mainExecutor 리스너). */
    private fun onPermissionLost(e: SecurityException) {
        Log.w(TAG, "location permission lost", e)
        stopUpdates()
        stopTransitions()
        stopSelf()
    }

    /** 알림 권한(Android 13+)이 없으면 보이지 않을 뿐 서비스는 돈다. */
    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                getString(R.string.location_record_channel_name),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        val open = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val stop = PendingIntent.getService(
            this,
            NOTIFICATION_ID,
            Intent(this, LocationRecordService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val title = getString(
            if (mode == LocationRecordRules.MODE_DENSE) {
                R.string.location_record_notification_dense
            } else {
                R.string.location_record_notification_normal
            },
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_location)
            .setContentTitle(title)
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .addAction(
                Notification.Action.Builder(
                    null,
                    getString(R.string.location_record_stop),
                    stop,
                ).build(),
            )
            .build()
    }
}
