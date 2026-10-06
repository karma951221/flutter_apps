package com.karma.walk

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.MainThread
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * 앱 밖에서 알람 예약을 다시 채우는 공용 실행기. 시간대 변경 수신기(`TimeZoneChangedReceiver`)와
 * 하루 한 번 작업(`DailyAlarmSyncWorker`)이 함께 쓴다. 예약 규칙은 Dart(`AlarmUseCase`)에만 있으므로
 * Dart 를 부른다.
 *
 * - 메인 엔진이 살아 있으면(앱이 떠 있음) 그 엔진에 `walk/background` 의 `resync` 를 요청한다.
 *   엔진을 하나 더 띄우면 `alarm` 플러그인의 네이티브 싱글턴이 두 번째 엔진에 붙었다가 destroy 때
 *   떨어진다.
 * - 없으면 헤드리스 엔진을 띄워 `alarmResyncMain` 을 돌리고 `done` 을 받으면 내린다.
 *
 * 프로세스 안에서 한 번에 하나만 돌고, 도는 중에 들어온 요청은 끝난 뒤 한 번 더 돈다([ResyncQueue]).
 * 모든 메서드는 메인 스레드에서 부른다.
 */
object AlarmResync {
    /** [run] 의 대기를 그만둔다. 실행 자체는 멈추지 않는다(다른 대기자 · 다음 실행이 있을 수 있다). */
    fun interface Handle {
        @MainThread
        fun cancel()
    }

    private const val TAG = "WalkAlarmResync"
    private const val CHANNEL = "walk/background"

    /** 다시 도는 실행을 기다리는 쪽이 모두 빠졌을 때의 한도. */
    private const val FALLBACK_TIMEOUT_MS = 9_000L

    private class Waiter(val timeoutMs: Long, val onEnd: (String) -> Unit, val timeout: Runnable)

    private val main = Handler(Looper.getMainLooper())
    private val queue = ResyncQueue<Waiter>()

    /** 지금 실행의 시간 초과 · 헤드리스 엔진. 실행이 끝나면 비운다. */
    private var runTimeout: Runnable? = null
    private var headless: FlutterEngine? = null
    private var runId = 0

    /**
     * resync 를 요청한다. 끝나면(응답 · 오류 · [timeoutMs] 초과 중 먼저 온 것) [onEnd] 를 한 번
     * 부른다. 도는 중이면 지금 실행이 끝난 뒤 한 번 더 돌고, 그 실행이 끝날 때 부른다.
     */
    @MainThread
    fun run(context: Context, timeoutMs: Long, onEnd: (reason: String) -> Unit): Handle {
        lateinit var waiter: Waiter
        var ended = false
        val end: (String) -> Unit = { reason ->
            if (!ended) {
                ended = true
                main.removeCallbacks(waiter.timeout)
                onEnd(reason)
            }
        }
        waiter = Waiter(timeoutMs, end, Runnable {
            queue.cancel(waiter)
            end("timeout")
        })
        main.postDelayed(waiter.timeout, timeoutMs)
        if (queue.request(waiter)) {
            start(context.applicationContext, timeoutMs)
        } else {
            Log.i(TAG, "already running, will run once more")
        }
        return Handle {
            queue.cancel(waiter)
            main.removeCallbacks(waiter.timeout)
            ended = true
        }
    }

    private fun start(context: Context, timeoutMs: Long) {
        val id = ++runId
        // 응답 · 오류 · 시간 초과 중 먼저 온 것 한 번만. 이 실행이 이미 끝났으면 무시한다.
        val finish: (String) -> Unit = { reason -> if (id == runId) finish(context, reason) }
        val timeout = Runnable { finish("timeout") }
        runTimeout = timeout
        main.postDelayed(timeout, timeoutMs)
        try {
            val engine = MainActivity.engine
            if (engine != null) {
                resyncOnMainEngine(engine, finish)
            } else {
                headless = startHeadless(context) { reason -> main.post { finish(reason) } }
            }
        } catch (e: Exception) {
            Log.e(TAG, "resync failed to start", e)
            finish("error")
        }
    }

    private fun finish(context: Context, reason: String) {
        runId++
        runTimeout?.let(main::removeCallbacks)
        runTimeout = null
        headless?.destroy()
        headless = null
        Log.i(TAG, "finish: $reason")
        val done = queue.finish()
        for (waiter in done.served) waiter.onEnd(reason)
        if (done.again) {
            Log.i(TAG, "run once more")
            // 다음 실행의 한도는 그 실행을 기다리는 쪽 중 가장 긴 것. 모두 빠졌으면 짧게 잡는다.
            start(context, queue.waiting().maxOfOrNull { it.timeoutMs } ?: FALLBACK_TIMEOUT_MS)
        }
    }

    private fun resyncOnMainEngine(engine: FlutterEngine, onEnd: (String) -> Unit) {
        Log.i(TAG, "resync on main engine")
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .invokeMethod(
                "resync",
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) = onEnd("main engine resynced")

                    override fun error(code: String, message: String?, details: Any?) =
                        onEnd("main engine error $code")

                    override fun notImplemented() = onEnd("main engine not ready")
                },
            )
    }

    private fun startHeadless(context: Context, onDone: (String) -> Unit): FlutterEngine {
        Log.i(TAG, "start headless engine")
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(context)
        loader.ensureInitializationComplete(context, null)
        val engine = FlutterEngine(context)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "done") {
                    result.success(null)
                    onDone("headless done")
                } else {
                    result.notImplemented()
                }
            }
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "alarmResyncMain"),
        )
        return engine
    }
}
