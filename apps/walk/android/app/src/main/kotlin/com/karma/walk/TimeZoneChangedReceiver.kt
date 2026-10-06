package com.karma.walk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 시간대가 바뀌면 알람 예약(절대 시각)을 새 시간대의 벽시계에 맞춰 다시 건다. 실행은
 * [BackgroundDispatcher] 가 맡는다(메인 엔진이 있으면 `resync`, 없으면 헤드리스).
 *
 * goAsync 한도(10초) 안에 끝나도록 [TIMEOUT_MS] 뒤에는 기다리지 않고 끝낸다.
 */
class TimeZoneChangedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_TIMEZONE_CHANGED) return
        Log.i(TAG, "timezone changed")
        val pending = goAsync()
        // onReceive 는 메인 스레드에서 불린다.
        BackgroundDispatcher.dispatch(context, BackgroundJob.resync, TIMEOUT_MS) { _, reason ->
            Log.i(TAG, "finish: $reason")
            pending.finish()
        }
    }

    private companion object {
        const val TAG = "WalkTzReceiver"
        const val TIMEOUT_MS = 9_000L
    }
}
