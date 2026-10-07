package com.karma.walk

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.MainThread
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * 앱 밖에서 Dart 를 부르는 백그라운드 일 하나. 메인 엔진이 있으면 `walk/background` 의
 * [method]([arguments])를, 없으면 헤드리스 엔진에서 [entrypoint]([entrypointArgs])를 돌린다.
 * 같은 값이면 같은 일이다([BackgroundQueue] 가 묶는다).
 */
data class BackgroundJob(
    val method: String,
    val arguments: Any?,
    val entrypoint: String,
    val entrypointArgs: List<String> = emptyList(),
) {
    companion object {
        /** 알람 예약 다시 채우기(시간대 변경 · 하루 한 번 작업). 예약 규칙은 Dart(`AlarmUseCase`)에만 있다. */
        val resync = BackgroundJob("resync", null, "alarmResyncMain")

        /** 미리 알림의 [이번만 끄기] · [다음 알람 건너뛰기] — Dart `skipOccurrence(packageId)`. */
        fun reminderSkip(packageId: Int) = BackgroundJob(
            "reminderAction",
            mapOf("action" to "skip", "packageId" to packageId),
            "alarmReminderActionMain",
            listOf("skip", packageId.toString()),
        )
    }
}

/**
 * 앱 밖에서 Dart 를 부르는 공용 실행기(웨이브 1 `AlarmResync` 를 일반화). 시간대 변경 수신기
 * (`TimeZoneChangedReceiver`) · 하루 한 번 작업(`DailyAlarmSyncWorker`) · 미리 알림 액션
 * (`ReminderActionReceiver`)이 함께 쓴다.
 *
 * - 메인 엔진이 살아 있으면(앱이 떠 있음) 그 엔진에 `walk/background` 로 일을 요청한다.
 *   엔진을 하나 더 띄우면 그 엔진이 도는 동안 `alarm` 플러그인의 울림 이벤트가 두 번째 엔진으로 간다.
 *   헤드리스 실행 중에 앱 엔진이 새로 붙어도, 포크의 `AlarmPlugin` 이 엔진마다 API 를 따로 기억하므로
 *   헤드리스 엔진을 내릴 때 앱 엔진의 API 는 남는다(`third_party/alarm/FORK.md`, EngineRegistry).
 * - 없으면 헤드리스 엔진을 띄워 진입점을 돌리고 `done`(bool: 성공 여부)을 받으면 내린다. 헤드리스
 *   엔진에는 `walk/holidays`(하루 sync 가 sync 앞에 공휴일 캐시를 갱신) · `walk/reminders`(sync 가
 *   미리 알림을 맞춘다)를 붙인다.
 *
 * 프로세스 안에서 한 번에 하나만 돌고, 기다리는 일은 들어온 순서대로 돈다. 도는 중인 일과 같은
 * 일이 오면 끝난 뒤 한 번 더 돈다([BackgroundQueue]). 모든 메서드는 메인 스레드에서 부른다.
 *
 * 메인 엔진은 시작 · 복귀 sync 앞에 `walk/background` 의 `awaitIdle` 을 부른다([attachMainEngine]).
 * 헤드리스 일이 돌고 있으면 그 일이 끝날 때(또는 다음 실행이 메인 엔진으로 넘어갈 때) 답한다
 * ([HeadlessIdleGate]) — 헤드리스의 건너뛰기를 메인 엔진의 sync 가 덮지 않게.
 */
object BackgroundDispatcher {
    /** [dispatch] 의 대기를 그만둔다. 실행 자체는 멈추지 않는다(다른 대기자 · 다음 실행이 있을 수 있다). */
    fun interface Handle {
        @MainThread
        fun cancel()
    }

    private const val TAG = "WalkBackground"
    private const val CHANNEL = "walk/background"

    /** 다시 도는 실행을 기다리는 쪽이 모두 빠졌을 때의 한도. */
    private const val FALLBACK_TIMEOUT_MS = 9_000L

    private class Waiter(
        val timeoutMs: Long,
        val onEnd: (Boolean, String) -> Unit,
        val timeout: Runnable,
    )

    private val main = Handler(Looper.getMainLooper())
    private val queue = BackgroundQueue<BackgroundJob, Waiter>()
    private val idle = HeadlessIdleGate<MethodChannel.Result>()

    /** 지금 실행의 시간 초과 · 헤드리스 엔진. 실행이 끝나면 비운다. */
    private var runTimeout: Runnable? = null
    private var headless: FlutterEngine? = null
    private var runId = 0

    /**
     * 메인 엔진의 `walk/background` 에 `awaitIdle` 을 붙인다. [MainActivity] 가 엔진을 설정할 때 부른다.
     * (같은 채널로 이 실행기가 메인 엔진에 `resync` · `reminderAction` 을 보내는 방향과는 따로다.)
     */
    @MainThread
    fun attachMainEngine(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "awaitIdle") {
                if (idle.await(result)) {
                    result.success(null)
                } else {
                    Log.i(TAG, "awaitIdle: waiting for headless run")
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun release(waiters: List<MethodChannel.Result>) {
        for (waiter in waiters) waiter.success(null)
    }

    /**
     * [job] 을 요청한다. 끝나면(응답 · 오류 · [timeoutMs] 초과 중 먼저 온 것) [onEnd] 를 한 번
     * 부른다 — `ok` 는 Dart 가 성공을 알렸을 때만 true. 다른 일이 도는 중이면 그 뒤에 돈다.
     */
    @MainThread
    fun dispatch(
        context: Context,
        job: BackgroundJob,
        timeoutMs: Long,
        onEnd: (ok: Boolean, reason: String) -> Unit,
    ): Handle {
        lateinit var waiter: Waiter
        var ended = false
        val end: (Boolean, String) -> Unit = { ok, reason ->
            if (!ended) {
                ended = true
                main.removeCallbacks(waiter.timeout)
                onEnd(ok, reason)
            }
        }
        waiter = Waiter(timeoutMs, end, Runnable {
            queue.cancel(waiter)
            end(false, "timeout")
        })
        main.postDelayed(waiter.timeout, timeoutMs)
        if (queue.request(job, waiter)) {
            start(context.applicationContext, job, timeoutMs)
        } else {
            Log.i(TAG, "busy, queued ${job.method}")
        }
        return Handle {
            queue.cancel(waiter)
            main.removeCallbacks(waiter.timeout)
            ended = true
        }
    }

    private fun start(context: Context, job: BackgroundJob, timeoutMs: Long) {
        val id = ++runId
        // 응답 · 오류 · 시간 초과 중 먼저 온 것 한 번만. 이 실행이 이미 끝났으면 무시한다.
        val finish: (Boolean, String) -> Unit = { ok, reason ->
            if (id == runId) finish(context, ok, reason)
        }
        val timeout = Runnable { finish(false, "timeout") }
        runTimeout = timeout
        main.postDelayed(timeout, timeoutMs)
        try {
            val engine = MainActivity.engine
            if (engine != null) {
                release(idle.started(headless = false))
                runOnMainEngine(engine, job, finish)
            } else {
                idle.started(headless = true)
                headless = startHeadless(context, job) { ok, reason ->
                    main.post { finish(ok, reason) }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "${job.method} failed to start", e)
            finish(false, "error")
        }
    }

    private fun finish(context: Context, ok: Boolean, reason: String) {
        runId++
        runTimeout?.let(main::removeCallbacks)
        runTimeout = null
        headless?.destroy()
        headless = null
        Log.i(TAG, "finish: $reason (ok=$ok)")
        val done = queue.finish()
        for (waiter in done.served) waiter.onEnd(ok, reason)
        val next = done.next
        if (next == null) {
            release(idle.stopped())
            return
        }
        Log.i(TAG, "run next: ${next.method}")
        // 다음 실행의 한도는 그 실행을 기다리는 쪽 중 가장 긴 것. 모두 빠졌으면 짧게 잡는다.
        start(context, next, queue.waiting().maxOfOrNull { it.timeoutMs } ?: FALLBACK_TIMEOUT_MS)
    }

    /** 응답이 `false` 면 실패, 그 밖의 성공 응답(`resync` 의 null 등)은 성공이다. */
    private fun runOnMainEngine(
        engine: FlutterEngine,
        job: BackgroundJob,
        onEnd: (Boolean, String) -> Unit,
    ) {
        Log.i(TAG, "${job.method} on main engine")
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .invokeMethod(
                job.method,
                job.arguments,
                object : MethodChannel.Result {
                    override fun success(result: Any?) =
                        onEnd(result != false, "main engine done")

                    override fun error(code: String, message: String?, details: Any?) =
                        onEnd(false, "main engine error $code")

                    override fun notImplemented() = onEnd(false, "main engine not ready")
                },
            )
    }

    private fun startHeadless(
        context: Context,
        job: BackgroundJob,
        onDone: (Boolean, String) -> Unit,
    ): FlutterEngine {
        Log.i(TAG, "start headless engine: ${job.entrypoint}")
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)
        val engine = FlutterEngine(context)
        // 진입점을 돌리기 전에 채널을 붙인다. 하루 sync 는 sync 앞에 공휴일 캐시를 갱신하고(앱을 오래
        // 열지 않아도 하루 한 번 읽게), 어느 sync 든 미리 알림을 맞춘다.
        HolidayCalendarChannel.attach(context, engine)
        ReminderChannel.attach(context, engine.dartExecutor.binaryMessenger)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "done") {
                    result.success(null)
                    onDone(call.arguments == true, "headless done")
                } else {
                    result.notImplemented()
                }
            }
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), job.entrypoint),
            job.entrypointArgs,
        )
        return engine
    }
}
