package com.karma.walk

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log

/**
 * 미리 알림을 AlarmManager 에 걸고 알림으로 띄운다. setAlarmClock 은 쓰지 않는다 — 상태바의
 * "다음 알람" 표시는 진짜 알람(패키지) 몫이다. 정확 알람을 못 쓰면 정확하지 않은 알람으로 낮춘다.
 */
internal object ReminderAlarms {
    const val ACTION_FIRE = "com.karma.walk.REMINDER_FIRE"
    const val ACTION_SKIP = "com.karma.walk.REMINDER_SKIP"
    const val ACTION_DISMISS = "com.karma.walk.REMINDER_DISMISS"
    const val EXTRA_ID = "id"
    const val EXTRA_PACKAGE_ID = "packageId"

    private const val TAG = "WalkReminders"
    private const val CHANNEL_ID = "walk_alarm_reminder"

    /** `schedule`: 저장하고 걸거나(띄울 시각 전) 바로 띄운다. 떠 있던 옛 알림은 걷는다. */
    fun schedule(context: Context, entry: ReminderEntry, nowMillis: Long) {
        dismiss(context, entry.id)
        when (ReminderRules.onSchedule(entry, nowMillis)) {
            ReminderRules.Schedule.ARM -> {
                ReminderStore.edit(context) { it.put(entry) }
                arm(context, entry)
            }
            ReminderRules.Schedule.SHOW_NOW -> {
                disarm(context, entry.id)
                ReminderStore.edit(context) {
                    it.put(entry)
                    it.markShown(entry.id)
                }
                show(context, entry)
            }
            ReminderRules.Schedule.DROP -> cancel(context, entry.id)
        }
    }

    /** `cancel`: 예약 · 떠 있는 알림 · 저장 항목을 모두 지운다. */
    fun cancel(context: Context, id: Int) {
        disarm(context, id)
        dismiss(context, id)
        ReminderStore.edit(context) { it.remove(id) }
    }

    fun arm(context: Context, entry: ReminderEntry) {
        val manager = context.getSystemService(AlarmManager::class.java)
        val intent = fireIntent(context, entry.id)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
        try {
            if (exact) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.atMillis, intent)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.atMillis, intent)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "exact alarm denied, falling back to inexact", e)
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.atMillis, intent)
        }
    }

    fun disarm(context: Context, id: Int) {
        context.getSystemService(AlarmManager::class.java).cancel(fireIntent(context, id))
    }

    /** 알림을 띄운다. 알림 권한이 없으면 시스템이 조용히 무시한다. */
    fun show(context: Context, entry: ReminderEntry) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.reminder_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            ),
        )
        val open = PendingIntent.getActivity(
            context,
            entry.id,
            Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_alarm)
            .setContentTitle(entry.title)
            .setContentText(entry.body)
            .setStyle(Notification.BigTextStyle().bigText(entry.body))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setContentIntent(open)
            .setAutoCancel(true)
        for (action in entry.actions) {
            val name = when (action.action) {
                "skip" -> ACTION_SKIP
                "dismiss" -> ACTION_DISMISS
                else -> continue
            }
            val intent = Intent(context, ReminderActionReceiver::class.java)
                .setAction(name)
                .putExtra(EXTRA_ID, entry.id)
                .putExtra(EXTRA_PACKAGE_ID, entry.packageId)
            // request code 가 같아도 action 이 달라 서로 다른 PendingIntent 다.
            val pending = PendingIntent.getBroadcast(
                context,
                entry.id,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            builder.addAction(
                Notification.Action.Builder(
                    Icon.createWithResource(context, R.drawable.ic_stat_alarm),
                    action.label,
                    pending,
                ).build(),
            )
        }
        try {
            manager.notify(entry.id, builder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "notification denied", e)
        }
    }

    fun dismiss(context: Context, id: Int) {
        context.getSystemService(NotificationManager::class.java).cancel(id)
    }

    private fun fireIntent(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, ReminderFireReceiver::class.java)
            .setAction(ACTION_FIRE)
            .putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}
