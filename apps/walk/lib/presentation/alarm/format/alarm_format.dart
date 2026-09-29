import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm.dart';

/// 알람 화면의 시각 · 남은 시간 · 울릴 날 · 반복 요약 표기.
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

  /// 다음 울림까지 — `7시간 12분 후`. [duration] 규칙(분 올림)을 그대로 쓴다.
  static String remaining(AppLocalizations l10n, Duration remaining) =>
      l10n.walkAlarmIn(duration(l10n, remaining));

  /// 울릴 날 — `오늘 (월)`, `내일 (화)`, `10월 3일 (금)`. 오늘 · 내일은 [now] 의 날짜로 가린다.
  static String day(AppLocalizations l10n, DateTime at, DateTime now) {
    final locale = l10n.localeName;
    final date = DateTime(at.year, at.month, at.day);
    final String name;
    if (date == DateTime(now.year, now.month, now.day)) {
      name = l10n.walkAlarmDayToday;
    } else if (date == DateTime(now.year, now.month, now.day + 1)) {
      name = l10n.walkAlarmDayTomorrow;
    } else {
      name = DateFormat.MMMd(locale).format(at);
    }
    return '$name (${DateFormat.E(locale).format(at)})';
  }

  /// 울릴 날과 시각 — `내일 (화) 오전 7:00`.
  static String ringAt(BuildContext context, DateTime at, DateTime now) =>
      '${day(AppLocalizations.of(context), at, now)} ${time(context, at.hour, at.minute)}';

  /// 가장 먼저 울릴 알람 id. 시각이 같으면 id 가 작은 것. 비면 null.
  static int? earliest(Map<int, DateTime> nextAt) {
    int? best;
    for (final MapEntry(key: id, value: at) in nextAt.entries) {
      if (best == null) {
        best = id;
        continue;
      }
      final bestAt = nextAt[best]!;
      if (at.isBefore(bestAt) || (at == bestAt && id < best)) best = id;
    }
    return best;
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
