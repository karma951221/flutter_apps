package com.karma.walk

import com.karma.walk.HolidayCalendarRules.CalendarRow
import com.karma.walk.HolidayCalendarRules.InstanceRow
import com.karma.walk.HolidayCalendarRules.Picked
import java.time.LocalDate
import java.time.temporal.JulianFields
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class HolidayCalendarRulesTest {
    private fun row(
        id: Long,
        accountType: String? = "com.google",
        owner: String? = null,
        calSync1: String? = null,
        syncId: String? = null,
        name: String? = "x",
        syncEvents: Int = 1,
    ) = CalendarRow(id, accountType, owner, calSync1, syncId, name, syncEvents)

    private val ko = "ko.south_korea#holiday@group.v.calendar.google.com"

    @Test
    fun `구글 한국 휴일 캘린더를 OWNER_ACCOUNT 로 고른다`() {
        val picked = HolidayCalendarRules.pick(
            listOf(
                row(1, owner = "me@gmail.com", name = "me@gmail.com"),
                row(2, owner = ko, name = "대한민국의 휴일"),
            ),
        )
        assertEquals(listOf(Picked(2, "대한민국의 휴일", official = false)), picked)
    }

    @Test
    fun `official 캘린더 · 영어 피드도 고른다`() {
        val picked = HolidayCalendarRules.pick(
            listOf(
                row(1, owner = "ko.south_korea.official#holiday@group.v.calendar.google.com", name = "공휴일"),
                row(2, owner = "en.south_korea#holiday@group.v.calendar.google.com", name = "Holidays in South Korea"),
            ),
        )
        assertEquals(
            listOf(Picked(1, "공휴일", official = true), Picked(2, "Holidays in South Korea", official = false)),
            picked,
        )
    }

    @Test
    fun `id 가 CAL_SYNC1 이나 _SYNC_ID 에 있어도 고른다`() {
        val picked = HolidayCalendarRules.pick(
            listOf(row(1, owner = "me@gmail.com", calSync1 = ko), row(2, syncId = ko)),
        )
        assertEquals(listOf(1L, 2L), picked.map { it.id })
    }

    @Test
    fun `다른 나라 휴일 · 구글 계정이 아닌 행 · 동기화 꺼진 행은 id 로 고르지 않는다`() {
        val picked = HolidayCalendarRules.pick(
            listOf(
                row(1, owner = "ko.japanese#holiday@group.v.calendar.google.com", name = "일본의 휴일"),
                row(2, accountType = "LOCAL", owner = ko, name = "내 캘린더"),
                row(3, owner = ko, name = "대한민국의 휴일", syncEvents = 0),
            ),
        )
        // 다른 나라 구글 휴일 캘린더는 이름에 "휴일" 이 있어도 이름 보조 규칙으로도 고르지 않는다.
        assertEquals(emptyList<Long>(), picked.map { it.id })
    }

    @Test
    fun `구글 휴일 캘린더가 있으면 이름 보조 규칙은 쓰지 않는다`() {
        val picked = HolidayCalendarRules.pick(
            listOf(row(1, owner = ko, name = "대한민국의 휴일"), row(2, accountType = "LOCAL", name = "공휴일")),
        )
        assertEquals(listOf(1L), picked.map { it.id })
    }

    @Test
    fun `구글 휴일 캘린더가 없으면 이름에 휴일 · 공휴일 · holiday 가 든 캘린더`() {
        val picked = HolidayCalendarRules.pick(
            listOf(
                row(1, accountType = "LOCAL", name = "대한민국의 휴일"),
                row(2, accountType = "com.samsung", name = "공휴일"),
                row(3, accountType = "LOCAL", name = "Holidays in South Korea"),
                row(4, accountType = "LOCAL", name = "회사"),
                row(5, accountType = "LOCAL", name = null),
                row(6, accountType = "LOCAL", name = "휴일", syncEvents = 0),
            ),
        )
        assertEquals(listOf(1L, 2L, 3L), picked.map { it.id })
        // 이름으로 찾은 캘린더(다른 앱 · 로컬)는 설명을 비워 두는 일이 많다 — 설명을 몰라도 쉬는 날로 본다.
        assertTrue(picked.all { it.official })
    }

    @Test
    fun `이름으로 찾은 로컬 휴일 캘린더의 설명 없는 종일 일정도 공휴일 · 기념일은 뺀다`() {
        val picked = HolidayCalendarRules.pick(listOf(row(7, accountType = "LOCAL", name = "대한민국의 휴일")))
        val days = HolidayCalendarRules.holidays(
            listOf(
                instance(7, LocalDate.of(2026, 10, 9), "한글날", description = null),
                instance(7, LocalDate.of(2026, 10, 3), "개천절", description = ""),
                instance(7, LocalDate.of(2026, 5, 8), "어버이날", description = "기념일"),
            ),
            picked,
        )
        assertEquals(
            mapOf(LocalDate.of(2026, 10, 3) to "개천절", LocalDate.of(2026, 10, 9) to "한글날"),
            days,
        )
    }

    @Test
    fun `쉬는 날 판정은 설명 첫 줄`() {
        assertTrue(HolidayCalendarRules.isDayOff("공휴일", official = false))
        assertTrue(HolidayCalendarRules.isDayOff("Public holiday", official = false))
        assertTrue(HolidayCalendarRules.isDayOff("  공휴일 \n", official = false))
        assertFalse(HolidayCalendarRules.isDayOff("기념일\n기념일을 숨기려면 Google Calendar 설정", official = false))
        assertFalse(HolidayCalendarRules.isDayOff("Observance\nTo hide observances", official = true))
    }

    @Test
    fun `모르는 설명은 official 캘린더일 때만 쉬는 날`() {
        assertTrue(HolidayCalendarRules.isDayOff(null, official = true))
        assertTrue(HolidayCalendarRules.isDayOff("Feiertag", official = true))
        assertFalse(HolidayCalendarRules.isDayOff(null, official = false))
        assertFalse(HolidayCalendarRules.isDayOff("", official = false))
    }

    private fun jd(date: LocalDate) = date.getLong(JulianFields.JULIAN_DAY).toInt()

    private fun instance(
        calendarId: Long,
        date: LocalDate,
        title: String,
        description: String? = "공휴일",
        allDay: Boolean = true,
        until: LocalDate = date,
    ) = InstanceRow(calendarId, allDay, jd(date), jd(until), title, description)

    @Test
    fun `종일 공휴일만 날짜 → 이름으로 모은다`() {
        val picked = listOf(Picked(1, "대한민국의 휴일", official = false))
        val days = HolidayCalendarRules.holidays(
            listOf(
                instance(1, LocalDate.of(2026, 10, 9), "한글날"),
                instance(1, LocalDate.of(2026, 10, 5), "쉬는 날 개천절"),
                instance(1, LocalDate.of(2026, 10, 1), "국군의날", description = "기념일\n…"),
                instance(1, LocalDate.of(2026, 10, 20), "시각 있는 일정", allDay = false),
                instance(9, LocalDate.of(2026, 10, 21), "다른 캘린더"),
            ),
            picked,
        )
        assertEquals(
            mapOf(LocalDate.of(2026, 10, 5) to "쉬는 날 개천절", LocalDate.of(2026, 10, 9) to "한글날"),
            days,
        )
        assertEquals(listOf(LocalDate.of(2026, 10, 5), LocalDate.of(2026, 10, 9)), days!!.keys.toList())
    }

    @Test
    fun `여러 날 일정은 날마다 · 같은 날은 먼저 온 이름`() {
        val picked = listOf(Picked(1, "a", official = false), Picked(2, "b", official = true))
        val days = HolidayCalendarRules.holidays(
            listOf(
                instance(1, LocalDate.of(2026, 9, 24), "추석 연휴", until = LocalDate.of(2026, 9, 26)),
                instance(2, LocalDate.of(2026, 9, 25), "Chuseok", description = null),
            ),
            picked,
        )
        assertEquals(
            mapOf(
                LocalDate.of(2026, 9, 24) to "추석 연휴",
                LocalDate.of(2026, 9, 25) to "추석 연휴",
                LocalDate.of(2026, 9, 26) to "추석 연휴",
            ),
            days,
        )
    }

    @Test
    fun `쉬는 날이 하나도 없으면 null(아직 동기화 전일 수 있다)`() {
        val picked = listOf(Picked(1, "a", official = false))
        assertNull(HolidayCalendarRules.holidays(emptyList(), picked))
        assertNull(
            HolidayCalendarRules.holidays(
                listOf(instance(1, LocalDate.of(2026, 5, 8), "어버이날", description = "기념일")),
                picked,
            ),
        )
    }
}
