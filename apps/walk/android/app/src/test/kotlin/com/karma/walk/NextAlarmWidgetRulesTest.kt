package com.karma.walk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDateTime
import java.time.ZoneId

class NextAlarmWidgetRulesTest {
    private val seoul = ZoneId.of("Asia/Seoul")

    private fun millis(y: Int, mo: Int, d: Int, h: Int = 0, mi: Int = 0) =
        LocalDateTime.of(y, mo, d, h, mi).atZone(seoul).toInstant().toEpochMilli()

    // 2026-10-07(수) 22:00
    private val now = millis(2026, 10, 7, 22)

    // ── 보일 회차 ──

    @Test
    fun `pick shows the earliest ring after now`() {
        val rings = listOf(
            WidgetRing(millis(2026, 10, 9, 7), "금요일"),
            WidgetRing(millis(2026, 10, 7, 21), "지남"),
            WidgetRing(millis(2026, 10, 8, 7), "출근"),
        )

        assertEquals(WidgetRing(millis(2026, 10, 8, 7), "출근"), NextAlarmWidgetRules.pick(rings, now))
    }

    @Test
    fun `pick skips a ring at exactly now and returns null when none is left`() {
        assertNull(NextAlarmWidgetRules.pick(listOf(WidgetRing(now, "")), now))
        assertNull(NextAlarmWidgetRules.pick(emptyList(), now))
    }

    // ── 날짜 문구 ──

    @Test
    fun `dayOf is today tomorrow or later by device date`() {
        assertEquals(WidgetDay.TODAY, NextAlarmWidgetRules.dayOf(millis(2026, 10, 7, 23, 59), now, seoul))
        assertEquals(WidgetDay.TOMORROW, NextAlarmWidgetRules.dayOf(millis(2026, 10, 8, 0, 0), now, seoul))
        assertEquals(WidgetDay.TOMORROW, NextAlarmWidgetRules.dayOf(millis(2026, 10, 8, 23, 59), now, seoul))
        assertEquals(WidgetDay.LATER, NextAlarmWidgetRules.dayOf(millis(2026, 10, 9, 0, 0), now, seoul))
    }

    @Test
    fun `dayOf follows the zone — the same instant is tomorrow in Seoul and today in UTC`() {
        val at = millis(2026, 10, 8, 7) // 서울 8일 07:00 = UTC 7일 22:00
        val utcNow = millis(2026, 10, 7, 23) // 서울 7일 23:00 = UTC 7일 14:00

        assertEquals(WidgetDay.TOMORROW, NextAlarmWidgetRules.dayOf(at, utcNow, seoul))
        assertEquals(WidgetDay.TODAY, NextAlarmWidgetRules.dayOf(at, utcNow, ZoneId.of("UTC")))
    }

    // ── 다시 그릴 때 ──

    @Test
    fun `refresh at the shown ring when it comes before next midnight`() {
        val rings = listOf(WidgetRing(millis(2026, 10, 7, 23, 30), ""))

        assertEquals(millis(2026, 10, 7, 23, 30) + 1, NextAlarmWidgetRules.nextRefreshAt(rings, now, seoul))
    }

    @Test
    fun `refresh at next midnight when the ring is later or there is none`() {
        val midnight = millis(2026, 10, 8)

        assertEquals(midnight, NextAlarmWidgetRules.nextRefreshAt(listOf(WidgetRing(millis(2026, 10, 8, 7), "")), now, seoul))
        assertEquals(midnight, NextAlarmWidgetRules.nextRefreshAt(emptyList(), now, seoul))
    }

    @Test
    fun `refresh is delivered within ten minutes of the planned time, not an open inexact window`() {
        // 일반 set 은 at + 0.75 × (at − now) 까지 늦을 수 있어 자정 문구가 반나절 밀린다.
        val window = NextAlarmWidgetRules.REFRESH_WINDOW_MILLIS

        assertEquals(true, window in 1..10 * 60 * 1000L)
    }
}
