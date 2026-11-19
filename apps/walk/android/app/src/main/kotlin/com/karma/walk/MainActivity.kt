package com.karma.walk

import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.view.ViewCompat
import com.karma.walk.location.LocationRecordChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        /** 떠 있는 메인 엔진. [BackgroundDispatcher] 가 헤드리스 엔진 대신 이것에 일을 부른다. */
        @Volatile
        var engine: FlutterEngine? = null
            private set
    }

    private var alarmSounds: AlarmSoundsChannel? = null

    /**
     * 알람음 "파일에서 고르기" 문서 선택기. STARTED 전에 등록해야 해서 `configureFlutterEngine`
     * (onCreate 안)에서 만들고, 결과는 [alarmSounds] 에 넘긴다.
     */
    private var pickAlarmFile: ActivityResultLauncher<Intent>? = null

    private var backupFiles: BackupFileChannel? = null

    /** 백업 파일 저장 위치 · 열 파일 고르기. [pickAlarmFile] 과 같은 이유로 엔진 준비 때 등록한다. */
    private var pickBackupDocument: ActivityResultLauncher<Intent>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // 위젯을 눌러 열었다(다시 만들어진 액티비티 · 최근 앱에서 연 옛 인텐트는 빼고).
        if (savedInstanceState == null) noteWidgetLaunch(intent)
        super.onCreate(savedInstanceState)
        // 하루 한 번 예약 채우기. 이미 걸려 있으면 그대로 둔다(KEEP).
        DailyAlarmSyncWorker.enqueue(applicationContext)
    }

    /**
     * 창이 다시 포커스를 받으면(복귀 · 알림 셰이드 · 시스템 창 닫힘) insets 를 다시 보내게 한다.
     * 키보드가 열린 채 나갔다 오면 엔진의 IME inset 이 키보드 높이로 남는(stale) 일이 있었다 —
     * 지금 창의 insets 로 다시 맞춘다.
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) ViewCompat.requestApplyInsets(window.decorView)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 떠 있던 앱을 위젯으로 다시 열었다. Dart 는 복귀(resumed)에서 `takeLaunch` 로 읽는다.
        noteWidgetLaunch(intent)
    }

    private fun noteWidgetLaunch(intent: Intent?) {
        if (intent?.action != NextAlarmWidgetProvider.ACTION_OPEN_ALARMS) return
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        WidgetChannel.launchPending = true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        engine = flutterEngine
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        // health 패키지에 Health Connect 설정 화면을 여는 API 가 없어 채널 하나를 둔다.
        MethodChannel(messenger, "com.karma.walk/health_connect")
            .setMethodCallHandler { call, result ->
                if (call.method != "openSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val opened = HealthSettingsRules.targets(Build.VERSION.SDK_INT, packageName).any { target ->
                    val intent = Intent(target.action)
                    target.packageName?.let { intent.putExtra(Intent.EXTRA_PACKAGE_NAME, it) }
                    try {
                        startActivity(intent)
                        true
                    } catch (e: ActivityNotFoundException) {
                        false
                    } catch (e: SecurityException) {
                        false
                    }
                }
                if (opened) result.success(null) else result.error("unavailable", null, null)
            }
        // 일기 잠금: 폰 화면 잠금이 없을 때 설정 화면으로 바로 보낸다.
        MethodChannel(messenger, "com.karma.walk/screen_lock")
            .setMethodCallHandler { call, result ->
                if (call.method != "openSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent(DevicePolicyManager.ACTION_SET_NEW_PASSWORD))
                    result.success(null)
                } catch (e: ActivityNotFoundException) {
                    try {
                        startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                        result.success(null)
                    } catch (e2: ActivityNotFoundException) {
                        result.error("unavailable", e2.message, null)
                    }
                }
            }
        // 물어보기 임시 대화: 보이는 동안 스크린샷 · 녹화 · 최근 앱 썸네일을 막는다.
        MethodChannel(messenger, "com.karma.walk/secure_window")
            .setMethodCallHandler { call, result ->
                if (call.method != "setSecure") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
        val launcher =
            pickAlarmFile
                ?: registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { picked ->
                    val uri = if (picked.resultCode == RESULT_OK) picked.data?.data else null
                    alarmSounds?.onDocumentPicked(uri)
                }.also { pickAlarmFile = it }
        alarmSounds =
            AlarmSoundsChannel(applicationContext, messenger) {
                // 영구 권한(takePersistableUriPermission)은 받지 않는다 — 고르자마자 복사한다.
                launcher.launch(
                    Intent(Intent.ACTION_OPEN_DOCUMENT)
                        .addCategory(Intent.CATEGORY_OPENABLE)
                        .setType("audio/*"),
                )
            }
        val backupLauncher =
            pickBackupDocument
                ?: registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { picked ->
                    val uri = if (picked.resultCode == RESULT_OK) picked.data?.data else null
                    backupFiles?.onDocument(uri)
                }.also { pickBackupDocument = it }
        backupFiles = BackupFileChannel(applicationContext, messenger) { backupLauncher.launch(it) }
        HolidayCalendarChannel.attach(applicationContext, flutterEngine)
        ReminderChannel.attach(applicationContext, messenger)
        RingLogChannel.attach(applicationContext, messenger)
        WidgetChannel.attach(applicationContext, messenger)
        // 지도: 상시 위치 기록 켜기 · 끄기 · 상태 · inbox 수거.
        LocationRecordChannel.attach(applicationContext, messenger)
        // 시작 · 복귀 sync 가 헤드리스 일(미리 알림 건너뛰기)이 끝나기를 기다린다(`awaitIdle`).
        BackgroundDispatcher.attachMainEngine(messenger)
        // permission_handler 의 캘린더 권한은 READ + WRITE 를 함께 요구한다 — 읽기만 묻는다.
        CalendarPermissionChannel(this, messenger)
        // permission_handler 에 전체 화면 알림(Android 14+) 확인 API 가 없어 채널을 둔다.
        MethodChannel(messenger, "walk/full_screen_intent")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUse" -> result.success(canUseFullScreenIntent())
                    "openSettings" -> {
                        openFullScreenIntentSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        if (engine === flutterEngine) engine = null
        // 알람음 선택 화면의 미리 듣기가 액티비티보다 오래 울리지 않게 한다.
        alarmSounds?.dispose()
        alarmSounds = null
        backupFiles?.dispose()
        backupFiles = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /** Android 13 이하는 매니페스트 선언만으로 허용된다. */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val manager = getSystemService(NotificationManager::class.java)
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings() {
        val uri = Uri.parse("package:$packageName")
        val intent =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT, uri)
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
            }
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri))
        }
    }
}
