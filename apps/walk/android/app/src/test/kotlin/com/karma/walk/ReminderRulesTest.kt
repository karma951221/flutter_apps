package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ReminderRulesTest {
    private val minute = 60_000L
    private val now = 1_000_000_000L

    private fun entry(
        id: Int = 1_002_406,
        at: Long = now + 10 * minute,
        ringAt: Long = now + 40 * minute,
        shown: Boolean = false,
    ) = ReminderEntry(
        id = id,
        packageId = 1203,
        kind = "soon",
        atMillis = at,
        ringAtMillis = ringAt,
        title = "곧 알람이 울려요",
        body = "오전 7:00 출근",
        actions = listOf(ReminderAction("skip", "이번만 끄기")),
        shown = shown,
    )

    // ── 저장소 계약(ChannelReminderScheduler 문서) ──

    @Test
    fun `scheduled lists armed and shown entries until ringAt`() {
        val book = ReminderBook()
        book.put(entry(id = 1))
        book.put(entry(id = 2, at = now - minute))
        book.markShown(2)
        book.put(entry(id = 3, at = now - 30 * minute, ringAt = now))

        assertEquals(listOf(1, 2), book.scheduled(now).map { it.id })
    }

    @Test
    fun `put overwrites the same id and clears shown`() {
        val book = ReminderBook()
        book.put(entry())
        book.markShown(1_002_406)

        book.put(entry(at = now + 20 * minute, ringAt = now + 50 * minute, shown = true))

        val saved = book.get(1_002_406)!!
        assertEquals(now + 20 * minute, saved.atMillis)
        assertFalse(saved.shown)
    }

    @Test
    fun `dismissed (shown) entry stays until ringAt, only remove or expiry deletes it`() {
        val book = ReminderBook()
        book.put(entry())
        book.markShown(1_002_406)

        assertTrue(book.get(1_002_406)!!.shown)
        assertEquals(listOf(1_002_406), book.scheduled(now + 39 * minute).map { it.id })

        assertEquals(listOf(1_002_406), book.pruneExpired(now + 40 * minute))
        assertNull(book.get(1_002_406))
    }

    @Test
    fun `remove deletes the entry`() {
        val book = ReminderBook()
        book.put(entry())

        book.remove(1_002_406)

        assertTrue(book.scheduled(now).isEmpty())
    }

    @Test
    fun `pruneExpired keeps entries whose ringAt is still ahead`() {
        val book = ReminderBook()
        book.put(entry(id = 1, ringAt = now))
        book.put(entry(id = 2, ringAt = now + 1))

        assertEquals(listOf(1), book.pruneExpired(now))
        assertEquals(listOf(2), book.all().map { it.id })
    }

    // ── 예약 · 띄우기 ──

    @Test
    fun `schedule arms a future reminder and shows a due one right away`() {
        assertEquals(ReminderRules.Schedule.ARM, ReminderRules.onSchedule(entry(), now))
        assertEquals(ReminderRules.Schedule.SHOW_NOW, ReminderRules.onSchedule(entry(at = now), now))
        assertEquals(
            ReminderRules.Schedule.SHOW_NOW,
            ReminderRules.onSchedule(entry(at = now - minute), now),
        )
    }

    @Test
    fun `schedule drops a reminder whose ring time has passed`() {
        assertEquals(
            ReminderRules.Schedule.DROP,
            ReminderRules.onSchedule(entry(at = now - 2 * minute, ringAt = now), now),
        )
    }

    @Test
    fun `fire shows a live entry, drops an expired one, ignores a missing one`() {
        assertEquals(ReminderRules.Fire.SHOW, ReminderRules.onFire(entry(at = now), now))
        assertEquals(ReminderRules.Fire.DROP, ReminderRules.onFire(entry(ringAt = now), now))
        assertEquals(ReminderRules.Fire.IGNORE, ReminderRules.onFire(null, now))
    }

    // ── 재부팅 · 업데이트 ──

    @Test
    fun `boot drops entries whose ring time has passed`() {
        assertEquals(ReminderRules.Boot.DROP, ReminderRules.onBoot(entry(ringAt = now), now))
        assertEquals(
            ReminderRules.Boot.DROP,
            ReminderRules.onBoot(entry(ringAt = now - minute, shown = true), now),
        )
    }

    @Test
    fun `boot keeps shown entries without showing them again`() {
        assertEquals(
            ReminderRules.Boot.KEEP,
            ReminderRules.onBoot(entry(at = now - minute, shown = true), now),
        )
    }

    @Test
    fun `boot re-arms reminders still in the future`() {
        assertEquals(ReminderRules.Boot.ARM, ReminderRules.onBoot(entry(), now))
    }

    @Test
    fun `boot shows a missed reminder right away when more than a minute is left before ringing`() {
        assertEquals(
            ReminderRules.Boot.SHOW_NOW,
            ReminderRules.onBoot(entry(at = now - minute, ringAt = now + minute + 1), now),
        )
    }

    @Test
    fun `boot does not show a missed reminder a minute or less before ringing but keeps it`() {
        assertEquals(
            ReminderRules.Boot.MARK_SHOWN,
            ReminderRules.onBoot(entry(at = now - minute, ringAt = now + minute), now),
        )
    }
}
