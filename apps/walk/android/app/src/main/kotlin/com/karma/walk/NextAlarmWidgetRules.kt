package com.karma.walk

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/** 홈 화면 위젯에 실은 예약 한 회차(Dart `WidgetRing`). [title] 이 비면 제목 줄을 숨긴다. */
data class WidgetRing(val atMillis: Long, val title: String)

/** 위젯 날짜 문구의 종류 — 오늘 · 내일 · 그 뒤(날짜). */
enum class WidgetDay { TODAY, TOMORROW, LATER }

/**
 * 홈 화면 "다음 알람" 위젯의 순수 규칙(JUnit). 위젯은 Dart 가 넘긴 회차들 중 **그릴 때** 기기
 * 시각보다 뒤인 첫 회차를 보이고, 날짜 문구도 그때 기기 시간대로 계산한다 — 앱이 꺼진 채 알람이
 * 울려 sync 가 돌지 않거나 자정이 지나도 맞는 문구가 보이게.
 */
object NextAlarmWidgetRules {
    /** [nowMillis] 보다 뒤인 가장 이른 회차. 없으면 null("예정된 알람 없음"). */
    fun pick(rings: List<WidgetRing>, nowMillis: Long): WidgetRing? =
        rings.filter { it.atMillis > nowMillis }.minByOrNull { it.atMillis }

    fun dayOf(atMillis: Long, nowMillis: Long, zone: ZoneId): WidgetDay {
        val days = ChronoUnit.DAYS.between(dateOf(nowMillis, zone), dateOf(atMillis, zone))
        return when {
            days <= 0L -> WidgetDay.TODAY
            days == 1L -> WidgetDay.TOMORROW
            else -> WidgetDay.LATER
        }
    }

    /**
     * 다음에 다시 그릴 시각: 보이는 회차가 지나는 때(바로 다음 회차로 넘어가게)와 다음 자정(오늘 →
     * 내일 문구) 중 이른 것.
     */
    fun nextRefreshAt(rings: List<WidgetRing>, nowMillis: Long, zone: ZoneId): Long {
        val midnight = dateOf(nowMillis, zone).plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val shown = pick(rings, nowMillis)?.atMillis ?: return midnight
        return minOf(shown + 1, midnight)
    }

    /**
     * 다시 그리기 알람이 [nextRefreshAt] 뒤로 늦어져도 되는 폭. 일반 `AlarmManager.set` 은 API 19+ 에서
     * 정확하지 않아 at + 0.75 × (at − now) 까지 밀릴 수 있다 — 아침 8시에 건 자정 알람이 다음 날 정오에
     * 와서 그 사이 "내일" 문구나 이미 울린 회차가 남는다. `ACTION_DATE_CHANGED` 가 Android 8+ 매니페스트
     * 수신기에 오지 않으니 이 알람만이 문구를 넘긴다. `setWindow` 로 이 폭 안에 오게 한다(깨우지 않는
     * 창 알람이라 정확한 알람 권한이 필요 없다).
     */
    const val REFRESH_WINDOW_MILLIS: Long = 5 * 60 * 1000L

    private fun dateOf(millis: Long, zone: ZoneId): LocalDate =
        Instant.ofEpochMilli(millis).atZone(zone).toLocalDate()
}
