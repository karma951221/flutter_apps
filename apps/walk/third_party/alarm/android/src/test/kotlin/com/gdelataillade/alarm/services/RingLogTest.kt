package com.gdelataillade.alarm.services

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Fork: the ring log the walk app reads back on `walk/ring_log`.
 *
 * One JSON object per line, newest last, at most [RingLog.MAX_ENTRIES] lines.
 */
class RingLogTest {
    @Test
    fun `a line is one JSON object with at, packageId and kind`() {
        assertEquals(
            """{"at":1786086270000,"packageId":2047,"kind":"rang"}""",
            RingLog.line(1_786_086_270_000, 2047, RingLogKind.RANG),
        )
    }

    @Test
    fun `every kind has its wire name`() {
        assertEquals(
            listOf("rang", "stopped", "autoStopped", "snoozed", "skipped"),
            RingLogKind.values().map { it.wire },
        )
        assertEquals(RingLogKind.AUTO_STOPPED, RingLogKind.fromWire("autoStopped"))
        assertNull(RingLogKind.fromWire("dropped"))
    }

    @Test
    fun `appending to nothing stores the line alone`() {
        assertEquals("a", RingLog.appended(null, "a"))
        assertEquals("a", RingLog.appended("", "a"))
    }

    @Test
    fun `appending keeps the order, newest last`() {
        assertEquals("a\nb\nc", RingLog.appended("a\nb", "c"))
        assertEquals(listOf("a", "b", "c"), RingLog.lines("a\nb\nc"))
    }

    @Test
    fun `only the newest max lines are kept`() {
        assertEquals("b\nc\nd", RingLog.appended("a\nb\nc", "d", max = 3))
        val full = (1..RingLog.MAX_ENTRIES).joinToString("\n") { "$it" }
        val lines = RingLog.lines(RingLog.appended(full, "new"))
        assertEquals(RingLog.MAX_ENTRIES, lines.size)
        assertEquals("2", lines.first())
        assertEquals("new", lines.last())
    }

    @Test
    fun `lines of nothing is empty and blank lines are dropped`() {
        assertEquals(emptyList<String>(), RingLog.lines(null))
        assertEquals(emptyList<String>(), RingLog.lines(""))
        assertEquals(listOf("a", "b"), RingLog.lines("a\n\nb\n"))
    }

    @Test
    fun `a stop is logged only for a ringing alarm`() {
        assertEquals(RingLogKind.STOPPED, RingLog.stopKind(wasRinging = true, automatic = false))
        assertEquals(RingLogKind.AUTO_STOPPED, RingLog.stopKind(wasRinging = true, automatic = true))
        // Dart stops alarms that never rang too: cancelling, replacing, sync.
        assertNull(RingLog.stopKind(wasRinging = false, automatic = false))
        assertNull(RingLog.stopKind(wasRinging = false, automatic = true))
    }
}
