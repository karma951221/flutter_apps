package com.karma.walk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

/**
 * 디버그 빌드 전용. 하루 sync 를 기다리지 않고 지금 한 번 돌린다(에뮬레이터 확인용).
 *
 * ```
 * adb shell am broadcast -a com.karma.walk.DEBUG_DAILY_SYNC -p com.karma.walk
 * adb logcat -s WalkDailySync WalkAlarmResync
 * ```
 */
class DebugDailySyncReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        Log.i("WalkDailySync", "debug: enqueue one-time daily sync")
        WorkManager.getInstance(context)
            .enqueue(OneTimeWorkRequestBuilder<DailyAlarmSyncWorker>().build())
    }

    private companion object {
        const val ACTION = "com.karma.walk.DEBUG_DAILY_SYNC"
    }
}
