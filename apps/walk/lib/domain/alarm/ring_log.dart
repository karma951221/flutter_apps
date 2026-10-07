import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity/alarm.dart';
import 'entity/alarm_trigger.dart';
import 'entity/ring_log_entry.dart';

part 'ring_log.freezed.dart';

/// 울림 기록의 회차 하나(packageId + 날짜) 요약 — "7:00 울림 · 스누즈 2번 · 7:12 끔".
@freezed
class RingLogGroup with _$RingLogGroup {
  @override
  final int packageId;

  /// 지금 있는 알람. 지웠으면 null.
  @override
  final Alarm? alarm;

  /// 회차 시각 — 처음 울린 시각, 울리지 않았으면 건너뛴 회차 시각(그것도 없으면 첫 기록).
  @override
  final DateTime at;

  /// 처음 울린 시각. 울리지 않았으면 null.
  @override
  final DateTime? rangAt;

  @override
  final int snoozes;

  /// 마지막 끔([RingLogKind.stopped] · [RingLogKind.autoStopped]). 기록이 없으면 null.
  @override
  final RingLogKind? end;
  @override
  final DateTime? endedAt;

  /// 건너뛰었고 울리지 않았다. 건너뛰었다가 취소해 울렸으면 false.
  @override
  final bool skipped;

  const RingLogGroup({
    required this.packageId,
    required this.alarm,
    required this.at,
    required this.rangAt,
    required this.snoozes,
    required this.end,
    required this.endedAt,
    required this.skipped,
  });

  int get alarmId => alarmIdOf(packageId);
}

/// [entries] 를 회차(packageId + [RingLogEntry.at] 의 날짜)별로 묶는다. 최근 회차가 먼저.
/// [alarms] 에서 알람을 찾는다(지웠으면 null).
List<RingLogGroup> ringLogGroups(List<RingLogEntry> entries, List<Alarm> alarms) {
  final byId = {for (final a in alarms) a.id: a};
  final buckets = <(int, DateTime), List<RingLogEntry>>{};
  for (final e in [...entries]..sort((a, b) => a.at.compareTo(b.at))) {
    final key = (e.packageId, DateTime(e.at.year, e.at.month, e.at.day));
    (buckets[key] ??= []).add(e);
  }
  final groups = [
    for (final MapEntry(key: (packageId, _), value: events) in buckets.entries)
      _group(packageId, events, byId[alarmIdOf(packageId)]),
  ];
  return groups..sort((a, b) => b.at.compareTo(a.at));
}

RingLogGroup _group(int packageId, List<RingLogEntry> events, Alarm? alarm) {
  DateTime? first(RingLogKind kind) => events.where((e) => e.kind == kind).firstOrNull?.at;
  final ends = events.where(
    (e) => e.kind == RingLogKind.stopped || e.kind == RingLogKind.autoStopped,
  );
  final rangAt = first(RingLogKind.rang);
  final skippedAt = first(RingLogKind.skipped);
  return RingLogGroup(
    packageId: packageId,
    alarm: alarm,
    at: rangAt ?? skippedAt ?? events.first.at,
    rangAt: rangAt,
    snoozes: events.where((e) => e.kind == RingLogKind.snoozed).length,
    end: ends.lastOrNull?.kind,
    endedAt: ends.lastOrNull?.at,
    skipped: rangAt == null && skippedAt != null,
  );
}
