package com.karma.walk

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * `walk/calendar_permission` — 폰 캘린더 **읽기** 권한(`READ_CALENDAR`) 하나만 확인 · 요청한다.
 * `permission_handler` 의 캘린더 권한은 안드로이드에서 READ + WRITE 를 함께 요구해(매니페스트에 WRITE 가 없으면
 * 대화상자 없이 거부) 쓰지 않는다.
 *
 * - `check` · `request` → `granted` / `denied` / `permanentlyDenied`([CalendarPermissionRules]).
 * - `openSettings` → 앱 정보 화면.
 *
 * 요청 런처는 액티비티가 STARTED 되기 전에 등록해야 해서 `configureFlutterEngine`(onCreate 안)에서 만든다.
 */
class CalendarPermissionChannel(
    private val activity: FragmentActivity,
    messenger: BinaryMessenger,
) {
    companion object {
        const val NAME = "walk/calendar_permission"
        private const val PREFS = "walk.calendar_permission"
        private const val RATIONALE_SEEN = "rationaleSeen"
        private const val PERMISSION = Manifest.permission.READ_CALENDAR
    }

    private val pending = mutableListOf<MethodChannel.Result>()
    private val launcher: ActivityResultLauncher<String> =
        activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) {
            val status = status()
            val waiting = pending.toList()
            pending.clear()
            waiting.forEach { it.success(status) }
        }

    init {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "check" -> result.success(status())
                "request" -> request(result)
                "openSettings" -> {
                    openSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun request(result: MethodChannel.Result) {
        if (granted()) {
            result.success(CalendarPermissionRules.GRANTED)
            return
        }
        // 요청 전 rationale 도 기억한다(이번 대화상자에서 다시 거부하면 false 로 돌아간다).
        status()
        pending += result
        if (pending.size == 1) launcher.launch(PERMISSION)
    }

    private fun granted(): Boolean =
        ContextCompat.checkSelfPermission(activity, PERMISSION) == PackageManager.PERMISSION_GRANTED

    /** 지금 상태. rationale 을 봤으면 저장해 둔다. */
    private fun status(): String {
        val prefs = activity.getSharedPreferences(PREFS, android.content.Context.MODE_PRIVATE)
        val rationale = ActivityCompat.shouldShowRequestPermissionRationale(activity, PERMISSION)
        val previous = prefs.getBoolean(RATIONALE_SEEN, false)
        val seen = CalendarPermissionRules.seen(previous, rationale)
        if (seen != previous) prefs.edit().putBoolean(RATIONALE_SEEN, seen).apply()
        return CalendarPermissionRules.status(granted(), rationale, seen)
    }

    private fun openSettings() {
        val uri = Uri.parse("package:${activity.packageName}")
        try {
            activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri))
        } catch (e: ActivityNotFoundException) {
            activity.startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }
}
