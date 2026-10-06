package com.karma.walk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 재부팅 · 앱 업데이트 뒤 저장소에서 미리 알림을 다시 건다(Dart 없이 — 패키지 BootReceiver 와
 * 같은 수준의 복원). 규칙은 [ReminderRules.onBoot].
 */
class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        val now = System.currentTimeMillis()
        val toShow = mutableListOf<ReminderEntry>()
        val toArm = mutableListOf<ReminderEntry>()
        ReminderStore.edit(context) { book ->
            for (entry in book.all()) {
                when (ReminderRules.onBoot(entry, now)) {
                    ReminderRules.Boot.DROP -> book.remove(entry.id)
                    ReminderRules.Boot.KEEP -> Unit
                    ReminderRules.Boot.ARM -> toArm += entry
                    ReminderRules.Boot.SHOW_NOW -> {
                        book.markShown(entry.id)
                        toShow += entry
                    }
                    ReminderRules.Boot.MARK_SHOWN -> book.markShown(entry.id)
                }
            }
        }
        toArm.forEach { ReminderAlarms.arm(context, it) }
        toShow.forEach { ReminderAlarms.show(context, it) }
    }
}
