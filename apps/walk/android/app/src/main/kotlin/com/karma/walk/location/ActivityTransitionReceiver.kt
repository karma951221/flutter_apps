package com.karma.walk.location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

/**
 * Activity Transition(`STILL` 진입 · 이탈)을 받아 [LocationRecordService] 에 넘긴다. 서비스가 떠 있지
 * 않으면 버린다 — 서비스가 다시 뜨면 구독을 새로 걸고, 백그라운드에서 서비스를 시작할 수도 없다.
 */
class ActivityTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent)) return
        val result = ActivityTransitionResult.extractResult(intent) ?: return
        // 한 번에 여러 개가 오면 마지막 STILL 전환이 지금 상태다.
        val last = result.transitionEvents.lastOrNull { it.activityType == DetectedActivity.STILL } ?: return
        if (!LocationRecordService.running) return
        val entered = last.transitionType == ActivityTransition.ACTIVITY_TRANSITION_ENTER
        try {
            LocationRecordService.send(context, LocationRecordService.ACTION_TRANSITION) {
                putExtra(LocationRecordService.EXTRA_ENTERED_STILL, entered)
            }
        } catch (e: IllegalStateException) {
            Log.w("LocationRecord", "transition not delivered", e)
        }
    }
}
