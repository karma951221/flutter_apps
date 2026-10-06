package com.karma.walk

import java.time.LocalDate
import java.time.temporal.JulianFields

/**
 * 폰 캘린더(`CalendarContract`)에서 공휴일을 고르는 순수 규칙. [HolidayCalendarChannel] 이 커서를 이
 * 행들로 옮겨 부른다(웨이브 3 스펙 §2 결정 기록 · 스파이크 2026-10-06).
 */
object HolidayCalendarRules {
    /** `Calendars` 한 행. */
    data class CalendarRow(
        val id: Long,
        val accountType: String?,
        val ownerAccount: String?,
        val calSync1: String?,
        val syncId: String?,
        val displayName: String?,
        val syncEvents: Int,
    )

    /** 고른 휴일 캘린더. [official] 이면 설명을 몰라도 모든 일정을 공휴일로 본다. */
    data class Picked(val id: Long, val displayName: String, val official: Boolean)

    /** `Instances` 한 행. [startDay] · [endDay] 는 율리우스일(양 끝 포함). */
    data class InstanceRow(
        val calendarId: Long,
        val allDay: Boolean,
        val startDay: Int,
        val endDay: Int,
        val title: String?,
        val description: String?,
    )

    private const val GOOGLE = "com.google"
    private val KOREA_ID =
        Regex("""^[a-z_-]+\.south_korea(\.official)?#holiday@group\.v\.calendar\.google\.com$""")
    private val ANY_GOOGLE_HOLIDAY_ID = Regex("""#holiday@group\.v\.calendar\.google\.com$""")
    private val NAME_HINTS = listOf("휴일", "holiday")
    private val PUBLIC = listOf("공휴일", "Public holiday")
    private val OBSERVANCE = listOf("기념일", "Observance")

    /**
     * 휴일 캘린더를 고른다. 동기화가 꺼진(`SYNC_EVENTS = 0`) 행은 일정이 없을 수 있어 빼고, `VISIBLE` 은
     * 보지 않는다(화면에서 숨긴 것과 쉬는 날은 별개).
     * 1. 구글 계정의 한국 휴일 캘린더(id 가 `OWNER_ACCOUNT` · `CAL_SYNC1` · `_SYNC_ID` 중 하나에).
     * 2. 1 이 없으면 이름에 "휴일"(공휴일 포함) · "holiday" 가 든 캘린더(다른 앱 · 로컬). 다른 나라 구글
     *    휴일 캘린더는 뺀다.
     */
    fun pick(rows: List<CalendarRow>): List<Picked> {
        val live = rows.filter { it.syncEvents != 0 }
        val google = live.mapNotNull { row ->
            if (row.accountType != GOOGLE) return@mapNotNull null
            val id = listOf(row.ownerAccount, row.calSync1, row.syncId)
                .firstOrNull { it != null && KOREA_ID.matches(it) } ?: return@mapNotNull null
            Picked(row.id, row.displayName.orEmpty(), official = id.contains(".official#"))
        }
        if (google.isNotEmpty()) return google
        return live.mapNotNull { row ->
            val name = row.displayName ?: return@mapNotNull null
            val otherCountry = listOf(row.ownerAccount, row.calSync1, row.syncId)
                .any { it != null && ANY_GOOGLE_HOLIDAY_ID.containsMatchIn(it) }
            if (otherCountry) return@mapNotNull null
            if (NAME_HINTS.none { name.contains(it, ignoreCase = true) }) return@mapNotNull null
            Picked(row.id, name, official = false)
        }
    }

    /**
     * 설명 첫 줄이 `공휴일`/`Public holiday` 면 쉬는 날, `기념일`/`Observance` 면 아님. 그 밖의 문구는
     * [official] 캘린더일 때만 쉬는 날. 대체공휴일("쉬는 날 X") · 선거일도 `공휴일` 로 들어온다.
     */
    fun isDayOff(description: String?, official: Boolean): Boolean {
        val first = description?.lineSequence()?.firstOrNull()?.trim().orEmpty()
        return when {
            PUBLIC.any { first.startsWith(it, ignoreCase = true) } -> true
            OBSERVANCE.any { first.startsWith(it, ignoreCase = true) } -> false
            else -> official
        }
    }

    /**
     * [picked] 캘린더의 종일 공휴일을 날짜순 날짜 → 이름으로 모은다. 같은 날은 먼저 온 이름.
     * 하나도 없으면 null — 동기화 직후처럼 일정이 아직 없는 것일 수 있어 "공휴일 없음"으로 단정하지 않는다.
     */
    fun holidays(instances: List<InstanceRow>, picked: List<Picked>): Map<LocalDate, String>? {
        val official = picked.associate { it.id to it.official }
        val days = sortedMapOf<LocalDate, String>()
        for (row in instances) {
            val isOfficial = official[row.calendarId] ?: continue
            if (!row.allDay || !isDayOff(row.description, isOfficial)) continue
            val name = row.title?.trim().orEmpty()
            for (jd in row.startDay..row.endDay) {
                days.putIfAbsent(LocalDate.MIN.with(JulianFields.JULIAN_DAY, jd.toLong()), name)
            }
        }
        return days.ifEmpty { null }
    }
}
