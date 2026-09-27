import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';

/// 알람 화면의 시각 · 남은 시간 · 반복 요약 표기.
abstract final class AlarmFormat {
  static const _weekdays = {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri};
  static const _weekend = {Weekday.sat, Weekday.sun};

  /// 기기 언어 · 24시간제 설정을 따른다 — `오전 7:00`, `7:00 AM`, `07:00`.
  static String time(BuildContext context, int hour, int minute) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: hour, minute: minute),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  /// 남은 시간. 분은 올림한다 — 곧 울릴 알람이 "0분"으로 보이지 않게.
  /// 하루가 넘으면 분은 생략한다.
  static String duration(AppLocalizations l10n, Duration remaining) {
    final ceiled = (remaining.inSeconds / 60).ceil();
    final totalMinutes = ceiled < 1 ? 1 : ceiled;
    final days = totalMinutes ~/ (24 * 60);
    final hours = totalMinutes ~/ 60 % 24;
    final minutes = totalMinutes % 60;
    if (days > 0) {
      return hours > 0
          ? l10n.walkAlarmDurationDaysHours(days, hours)
          : l10n.walkAlarmDurationDays(days);
    }
    if (hours > 0) {
      return minutes > 0
          ? l10n.walkAlarmDurationHoursMinutes(hours, minutes)
          : l10n.walkAlarmDurationHours(hours);
    }
    return l10n.walkAlarmDurationMinutes(minutes);
  }

  /// 매일 · 평일 · 주말 · `월·수·금` · 1회.
  static String repeat(AppLocalizations l10n, Set<Weekday> days) {
    if (days.isEmpty) return l10n.walkAlarmRepeatOnce;
    if (days.length == Weekday.values.length) return l10n.walkAlarmRepeatDaily;
    if (_sameSet(days, _weekdays)) return l10n.walkAlarmRepeatWeekdays;
    if (_sameSet(days, _weekend)) return l10n.walkAlarmRepeatWeekends;
    return [
      for (final day in Weekday.values)
        if (days.contains(day)) weekday(l10n.localeName, day),
    ].join('·');
  }

  /// 짧은 요일 이름 — `월`, `Mon`, `月`.
  static String weekday(String locale, Weekday day) =>
      // 2024-01-01 은 월요일이다.
      DateFormat.E(locale).format(DateTime(2024, 1, 1 + day.index));

  static bool _sameSet(Set<Weekday> a, Set<Weekday> b) =>
      a.length == b.length && a.containsAll(b);
}
