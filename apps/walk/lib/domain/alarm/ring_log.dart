import 'package:freezed_annotation/freezed_annotation.dart';

import 'entity/alarm.dart';
import 'entity/alarm_trigger.dart';
import 'entity/ring_log_entry.dart';

part 'ring_log.freezed.dart';

/// 울림 기록의 회차 하나(packageId + 그 회차의 하루) 요약 — "7:00 울림 · 스누즈 2번 · 7:12 끔".
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

/// [entries] 를 회차별로 묶는다. 최근 회차가 먼저. [alarms] 에서 알람을 찾는다(지웠으면 null).
///
/// 회차는 packageId 와, 그 packageId 의 묶음이 시작된 지 [occurrenceSpan] 안인지로 정한다.
/// 스누즈 · 끔은 실제 시각으로 남아 자정을 넘길 수 있으니 기록 날짜로 나누지 않는다.
/// packageId 의 index 는 회차 날짜로 정해 100일마다 돌아오므로, 그보다 짧은 창이면 다른 회차와
/// 섞이지 않는다.
List<RingLogGroup> ringLogGroups(List<RingLogEntry> entries, List<Alarm> alarms) {
  final byId = {for (final a in alarms) a.id: a};
  final buckets = <List<RingLogEntry>>[];
  final open = <int, List<RingLogEntry>>{};
  for (final e in [...entries]..sort((a, b) => a.at.compareTo(b.at))) {
    final bucket = open[e.packageId];
    if (bucket != null && e.at.difference(bucket.first.at) < occurrenceSpan) {
      bucket.add(e);
    } else {
      buckets.add(open[e.packageId] = [e]);
    }
  }
  final groups = [
    for (final events in buckets)
      _group(events.first.packageId, events, byId[alarmIdOf(events.first.packageId)]),
  ];
  return groups..sort((a, b) => b.at.compareTo(a.at));
}

/// 한 회차의 기록이 걸칠 수 있는 최대 폭 — 첫 기록부터 이 안의 같은 packageId 는 같은 회차다.
const occurrenceSpan = Duration(days: 1);

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
