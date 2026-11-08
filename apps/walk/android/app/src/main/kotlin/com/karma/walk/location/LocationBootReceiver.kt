package com.karma.walk.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 재부팅 · 앱 업데이트 뒤 "기록 켜짐"이면 서비스를 다시 띄운다(Flutter 없이). 규칙은
 * [LocationRecordRules.shouldRestartOnBoot]. 알람 포크의 부팅 처리와는 따로 둔다.
 */
class LocationBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        val restart = LocationRecordRules.shouldRestartOnBoot(
            enabled = LocationRecordPrefs.enabled(context),
            hasBackgroundPermission = LocationRecordService.hasBackgroundPermission(context),
        )
        if (!restart) return
        // 재부팅 전 정지 단계는 믿을 수 없다 — 움직이는 중으로 시작하고 전환 구독이 바로잡는다.
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            LocationRecordPrefs.setPhase(context, LocationRecordRules.Phase.MOVING)
        }
        try {
            LocationRecordService.start(context)
        } catch (e: Exception) {
            // Android 12+ 포그라운드 서비스 시작 제한(부팅 · 업데이트 방송은 예외라 드물다).
            Log.w("LocationRecord", "restart on boot failed", e)
        }
    }
}
