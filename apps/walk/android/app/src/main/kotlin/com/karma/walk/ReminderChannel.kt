package com.karma.walk

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `walk/reminders` ↔ Dart `ChannelReminderScheduler`. 메인 엔진(`MainActivity`)과 헤드리스 엔진
 * (`BackgroundDispatcher`) 양쪽에 붙는다. 시각은 epoch millis.
 *
 * - `scheduled` → `[{id, at, ringAt}]`: 걸렸거나 떠 있는 것(울릴 시각 전). 띄운 항목은 알림이
 *   닫혀도 울릴 시각까지 남는다. 울릴 시각이 지난 항목은 여기서 지운다.
 * - `schedule` ← `{id, packageId, kind, at, ringAt, title, body, actions: [{action, label}]}`
 * - `cancel` ← `{id}`: 예약 · 떠 있는 알림 · 저장 항목 모두
 */
internal class ReminderChannel private constructor(private val context: Context) :
    MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "walk/reminders"

        fun attach(context: Context, messenger: BinaryMessenger) {
            MethodChannel(messenger, NAME)
                .setMethodCallHandler(ReminderChannel(context.applicationContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "scheduled" -> result.success(scheduled())
                "schedule" -> {
                    val entry = entryOf(call)
                    if (entry == null) {
                        result.error("bad_args", "schedule needs id, packageId, kind, at, ringAt, title, body", null)
                    } else {
                        ReminderAlarms.schedule(context, entry, System.currentTimeMillis())
                        result.success(null)
                    }
                }
                "cancel" -> {
                    val id = call.argument<Number>("id")?.toInt()
                    if (id == null) {
                        result.error("bad_args", "cancel needs id", null)
                    } else {
                        ReminderAlarms.cancel(context, id)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("failed", e.message, null)
        }
    }

    private fun scheduled(): List<Map<String, Any>> {
        val now = System.currentTimeMillis()
        val (expired, live) = ReminderStore.edit(context) { book ->
            book.pruneExpired(now) to book.scheduled(now)
        }
        for (id in expired) {
            ReminderAlarms.disarm(context, id)
            ReminderAlarms.dismiss(context, id)
        }
        return live.map { mapOf("id" to it.id, "at" to it.atMillis, "ringAt" to it.ringAtMillis) }
    }

    private fun entryOf(call: MethodCall): ReminderEntry? {
        val id = call.argument<Number>("id")?.toInt() ?: return null
        val actions = call.argument<List<Map<String, Any?>>>("actions").orEmpty().mapNotNull {
            val action = it["action"] as? String ?: return@mapNotNull null
            val label = it["label"] as? String ?: return@mapNotNull null
            ReminderAction(action, label)
        }
        return ReminderEntry(
            id = id,
            packageId = call.argument<Number>("packageId")?.toInt() ?: return null,
            kind = call.argument<String>("kind") ?: return null,
            atMillis = call.argument<Number>("at")?.toLong() ?: return null,
            ringAtMillis = call.argument<Number>("ringAt")?.toLong() ?: return null,
            title = call.argument<String>("title") ?: return null,
            body = call.argument<String>("body") ?: return null,
            actions = actions,
        )
    }
}
