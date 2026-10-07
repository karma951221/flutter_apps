package com.gdelataillade.alarm.services

import android.content.Context

/** Fork: what happened to a ring, as the walk app's ring log names it. */
enum class RingLogKind(val wire: String) {
    RANG("rang"),
    STOPPED("stopped"),
    AUTO_STOPPED("autoStopped"),
    SNOOZED("snoozed"),
    SKIPPED("skipped");

    companion object {
        fun fromWire(wire: String): RingLogKind? = values().firstOrNull { it.wire == wire }
    }
}

/**
 * Fork: a log of rings, stops and snoozes, written where they happen.
 *
 * Kept natively so a ring that starts and ends with no Flutter engine — the
 * app closed, the alarm stopped from its notification — is still recorded.
 * The walk app reads it back, and appends its own skips, through its
 * `walk/ring_log` channel; [PREFS_NAME] is the name both sides agree on.
 *
 * One JSON object per line (`{"at":millis,"packageId":id,"kind":"rang"}`),
 * newest last, at most [MAX_ENTRIES] lines.
 */
object RingLog {
    const val PREFS_NAME = "walk_ring_log"
    private const val KEY = "lines"
    const val MAX_ENTRIES = 200

    fun line(atMillis: Long, packageId: Int, kind: RingLogKind): String =
        """{"at":$atMillis,"packageId":$packageId,"kind":"${kind.wire}"}"""

    /** [existing] with [line] added last, keeping only the newest [max] lines. */
    fun appended(existing: String?, line: String, max: Int = MAX_ENTRIES): String =
        (lines(existing) + line).takeLast(max).joinToString("\n")

    fun lines(stored: String?): List<String> =
        stored.orEmpty().split('\n').filter { it.isNotBlank() }

    /**
     * What a stop command means for the log. Only a ringing alarm's stop is
     * logged: Dart stops alarms that never rang too (cancel, sync).
     */
    fun stopKind(wasRinging: Boolean, automatic: Boolean): RingLogKind? = when {
        !wasRinging -> null
        automatic -> RingLogKind.AUTO_STOPPED
        else -> RingLogKind.STOPPED
    }

    @Synchronized
    fun append(
        context: Context,
        packageId: Int,
        kind: RingLogKind,
        atMillis: Long = System.currentTimeMillis(),
    ) {
        val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val updated = appended(prefs.getString(KEY, null), line(atMillis, packageId, kind))
        // The ring service and receivers can be torn down right after, so write now.
        prefs.edit().putString(KEY, updated).commit()
    }

    @Synchronized
    fun read(context: Context): List<String> = lines(
        context.applicationContext
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY, null),
    )
}
