import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm_pause.freezed.dart';

/// 모든 알람을 쉬는 기간(웨이브 4 스펙 B4). 앱 전역 하나 — `AppSettings.pause`.
/// [from] ~ [until] 은 날짜 단위 포함 범위다(시각은 보지 않는다). 그 날짜의 회차는 모든 알람에서
/// 빠지고(1회성 포함), 스위치는 그대로다. [until] 이 지나면 sync 가 지운다.
@freezed
class AlarmPause with _$AlarmPause {
  /// 시작 날(로컬 자정).
  @override
  final DateTime from;

  /// 끝 날(로컬 자정, 포함).
  @override
  final DateTime until;

  const AlarmPause({required this.from, required this.until});

  /// 오늘만.
  static AlarmPause today(DateTime now) =>
      AlarmPause(from: _date(now), until: _date(now));

  /// 오늘부터 내일까지.
  static AlarmPause untilTomorrow(DateTime now) => AlarmPause(
    from: _date(now),
    until: DateTime(now.year, now.month, now.day + 1),
  );

  /// 이번 주말 — 평일이면 다가오는 토 · 일, 토요일이면 오늘 · 내일, 일요일이면 오늘만.
  static AlarmPause weekend(DateTime now) {
    final today = _date(now);
    if (now.weekday == DateTime.sunday) {
      return AlarmPause(from: today, until: today);
    }
    final toSaturday = DateTime.saturday - now.weekday;
    return AlarmPause(
      from: DateTime(now.year, now.month, now.day + toSaturday),
      until: DateTime(now.year, now.month, now.day + toSaturday + 1),
    );
  }

  /// [at] 의 날짜가 기간 안인가(시작 · 끝 날 포함).
  bool contains(DateTime at) {
    final day = _date(at);
    return !day.isBefore(_date(from)) && !day.isAfter(_date(until));
  }

  /// 끝 날이 [now] 의 날짜보다 앞이다(다 지났다).
  bool isOver(DateTime now) => _date(until).isBefore(_date(now));

  static DateTime _date(DateTime at) => DateTime(at.year, at.month, at.day);
}
