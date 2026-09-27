package com.karma.walk

import android.content.ActivityNotFoundException
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // health 패키지에 Health Connect 설정 화면을 여는 API 가 없어 채널 하나를 둔다.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.karma.walk/health_connect")
            .setMethodCallHandler { call, result ->
                if (call.method != "openSettings") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    startActivity(Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"))
                    result.success(null)
                } catch (e: ActivityNotFoundException) {
                    result.error("unavailable", e.message, null)
                }
            }
    }
}
