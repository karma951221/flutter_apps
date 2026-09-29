package com.karma.walk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * 시간대가 바뀌면 알람 예약(절대 시각)을 새 시간대의 벽시계에 맞춰 다시 건다.
 * 예약 규칙은 Dart(`AlarmUseCase.sync`)에만 있으므로 Dart 를 부른다.
 *
 * - 메인 엔진이 살아 있으면(앱이 떠 있음) 그 엔진에 `resync` 를 요청한다. 엔진을 하나 더 띄우면
 *   `alarm` 플러그인의 네이티브 싱글턴이 두 번째 엔진에 붙었다가 destroy 때 떨어진다.
 * - 없으면 헤드리스 엔진을 띄워 `alarmResyncMain` 을 돌리고 `done` 을 받으면 내린다.
 *
 * goAsync 한도(10초) 안에 끝나도록 [TIMEOUT_MS] 뒤에는 기다리지 않고 끝낸다.
 */
class TimeZoneChangedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_TIMEZONE_CHANGED) return
        Log.i(TAG, "timezone changed")
        val pending = goAsync()
        val main = Handler(Looper.getMainLooper())
        var finished = false
        var headless: FlutterEngine? = null

        // 응답 · 오류 · 시간 초과 중 먼저 온 것 한 번만. 모두 메인 스레드에서 부른다.
        fun finish(reason: String) {
            if (finished) return
            finished = true
            main.removeCallbacksAndMessages(null)
            headless?.destroy()
            headless = null
            Log.i(TAG, "finish: $reason")
            pending.finish()
        }

        main.postDelayed({ finish("timeout") }, TIMEOUT_MS)
        main.post {
            try {
                val engine = MainActivity.engine
                if (engine != null) {
                    resyncOnMainEngine(engine) { finish(it) }
                } else {
                    headless = startHeadless(context.applicationContext) { main.post { finish(it) } }
                }
            } catch (e: Exception) {
                Log.e(TAG, "resync failed to start", e)
                finish("error")
            }
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

    private companion object {
        const val TAG = "WalkTzReceiver"
        const val CHANNEL = "walk/background"
        const val TIMEOUT_MS = 9_000L
    }
}
