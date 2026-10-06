package com.karma.walk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 띄울 시각에 AlarmManager 가 깨운다. 저장 항목을 띄우고 띄운 것으로 표시한다. */
class ReminderFireReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReminderAlarms.ACTION_FIRE) return
        val id = intent.getIntExtra(ReminderAlarms.EXTRA_ID, -1)
        if (id < 0) return
        val now = System.currentTimeMillis()
        val (entry, fire) = ReminderStore.edit(context) { book ->
            val entry = book.get(id)
            val fire = ReminderRules.onFire(entry, now)
            if (fire == ReminderRules.Fire.SHOW) book.markShown(id)
            entry to fire
        }
        when (fire) {
            ReminderRules.Fire.SHOW -> ReminderAlarms.show(context, entry!!)
            ReminderRules.Fire.DROP -> ReminderAlarms.cancel(context, id)
            ReminderRules.Fire.IGNORE -> Unit
        }
    }
}
