package com.karma.walk

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 미리 알림 저장소. SharedPreferences `walk_reminders` 에 id → JSON 항목을 둔다(org.json — 의존성을
 * 늘리지 않는다). 규칙은 [ReminderBook] · [ReminderRules] 에 있고 여기는 읽고 쓰기만 한다.
 *
 * 채널(메인 스레드) · 수신기(메인 스레드)가 부르지만 한 번에 하나만 편집하도록 묶는다.
 */
internal object ReminderStore {
    private const val PREFS = "walk_reminders"

    @Synchronized
    fun <T> edit(context: Context, block: (ReminderBook) -> T): T {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val book = ReminderBook(
            prefs.all.values.mapNotNull { (it as? String)?.let(::decode) },
        )
        val result = block(book)
        val editor = prefs.edit().clear()
        for (entry in book.all()) editor.putString(entry.id.toString(), encode(entry))
        // 수신기는 곧 프로세스가 내려갈 수 있어 바로 쓴다(항목은 몇십 개).
        editor.commit()
        return result
    }

    private fun encode(entry: ReminderEntry): String = JSONObject()
        .put("id", entry.id)
        .put("packageId", entry.packageId)
        .put("kind", entry.kind)
        .put("at", entry.atMillis)
        .put("ringAt", entry.ringAtMillis)
        .put("title", entry.title)
        .put("body", entry.body)
        .put(
            "actions",
            JSONArray().apply {
                for (a in entry.actions) put(JSONObject().put("action", a.action).put("label", a.label))
            },
        )
        .put("shown", entry.shown)
        .toString()

    private fun decode(json: String): ReminderEntry? = try {
        val o = JSONObject(json)
        val actions = o.optJSONArray("actions") ?: JSONArray()
        ReminderEntry(
            id = o.getInt("id"),
            packageId = o.getInt("packageId"),
            kind = o.getString("kind"),
            atMillis = o.getLong("at"),
            ringAtMillis = o.getLong("ringAt"),
            title = o.getString("title"),
            body = o.getString("body"),
            actions = (0 until actions.length()).map {
                val a = actions.getJSONObject(it)
                ReminderAction(a.getString("action"), a.getString("label"))
            },
            shown = o.optBoolean("shown"),
        )
    } catch (e: Exception) {
        null
    }
}
