package com.karma.walk

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * 미리 알림 버튼. 무엇을 할지는 [ReminderBook.onAction] 이 정한다.
 *
 * - [울리기](`dismiss`): Dart 없이 알림만 닫는다. 저장 항목은 울릴 시각까지 남긴다(`shown`) —
 *   빠지면 다음 sync 가 다시 걸어 같은 알림이 또 뜬다.
 * - [이번만 끄기] · [다음 알람 건너뛰기](`skip`): [BackgroundDispatcher] 로 Dart
 *   `skipOccurrence(packageId)` 를 부른다(메인 엔진 우선, 없으면 헤드리스 `alarmReminderActionMain`).
 *   성공하면 알림을 닫고(저장 항목은 Dart sync 가 `cancel` 로 지운다), 실패 · 시간 초과면 알림을
 *   남겨 다시 누를 수 있게 한다.
 * - 울릴 시각이 지났거나 취소된 알림: Dart 에 보내지 않고 닫는다 — 울린 뒤 스누즈된 회차를 지우면 안 된다.
 */
class ReminderActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(ReminderAlarms.EXTRA_ID, -1)
        if (id < 0) return
        val name = when (intent.action) {
            ReminderAlarms.ACTION_DISMISS -> "dismiss"
            ReminderAlarms.ACTION_SKIP -> "skip"
            else -> return
        }
        val now = System.currentTimeMillis()
        when (ReminderStore.edit(context) { it.onAction(id, name, now) }) {
            ReminderRules.Action.CLOSE, ReminderRules.Action.STALE -> ReminderAlarms.dismiss(context, id)
            ReminderRules.Action.SKIP -> {
                val packageId = intent.getIntExtra(ReminderAlarms.EXTRA_PACKAGE_ID, -1)
                if (packageId < 0) return
                val pending = goAsync()
                // onReceive 는 메인 스레드에서 불린다. goAsync 한도(10초) 안에 끝낸다.
                BackgroundDispatcher.dispatch(
                    context,
                    BackgroundJob.reminderSkip(packageId),
                    TIMEOUT_MS,
                ) { ok, reason ->
                    Log.i(TAG, "skip $packageId: $reason (ok=$ok)")
                    if (ok) ReminderAlarms.dismiss(context, id)
                    pending.finish()
                }
            }
        }
    }

    private companion object {
        const val TAG = "WalkReminders"
        const val TIMEOUT_MS = 9_000L
    }
}
