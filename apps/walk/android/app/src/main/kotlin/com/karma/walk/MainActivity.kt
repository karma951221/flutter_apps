package com.karma.walk

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        /** 떠 있는 메인 엔진. 시간대 변경 수신기가 헤드리스 엔진 대신 이것에 `resync` 를 부른다. */
        @Volatile
        var engine: FlutterEngine? = null
            private set
    }

    private var alarmSounds: AlarmSoundsChannel? = null

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
                try {
                    startActivity(Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS"))
                    result.success(null)
                } catch (e: ActivityNotFoundException) {
                    result.error("unavailable", e.message, null)
                }
            }
        alarmSounds = AlarmSoundsChannel(applicationContext, messenger)
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
