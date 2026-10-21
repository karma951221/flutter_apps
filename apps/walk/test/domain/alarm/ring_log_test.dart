import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/ring_log.dart';

void main() {
  const work = Alarm(id: 1, hour: 7, minute: 0, label: '출근', repeat: {Weekday.mon});
  const gym = Alarm(id: 2, hour: 6, minute: 30, label: '운동', repeat: {Weekday.mon});
  // 2026-10-05 월요일.
  final monday7 = DateTime(2026, 10, 5, 7);
  int pid(int alarmId, DateTime at) => packageId(alarmId, triggerIndex(at));

  RingLogEntry entry(int alarmId, DateTime at, RingLogKind kind, {DateTime? occurrence}) =>
      RingLogEntry(at: at, packageId: pid(alarmId, occurrence ?? at), kind: kind);

  test('alarmId 는 packageId 에서 나온다', () {
    expect(entry(7, monday7, RingLogKind.rang).alarmId, 7);
  });

  test('한 회차의 울림 · 스누즈 · 다시 울림 · 끔을 한 묶음으로 센다', () {
    final groups = ringLogGroups(
      [
        entry(1, monday7, RingLogKind.rang),
        entry(1, DateTime(2026, 10, 5, 7, 1), RingLogKind.snoozed),
        entry(1, DateTime(2026, 10, 5, 7, 6), RingLogKind.rang),
        entry(1, DateTime(2026, 10, 5, 7, 7), RingLogKind.snoozed),
        entry(1, DateTime(2026, 10, 5, 7, 12), RingLogKind.rang),
        entry(1, DateTime(2026, 10, 5, 7, 12, 30), RingLogKind.stopped),
      ],
      [work],
    );

    expect(groups, [
      RingLogGroup(
        packageId: pid(1, monday7),
        alarm: work,
        at: monday7,
        rangAt: monday7,
        snoozes: 2,
        end: RingLogKind.stopped,
        endedAt: DateTime(2026, 10, 5, 7, 12, 30),
        skipped: false,
      ),
    ]);
  });

  test('자동 멈춤으로 끝난 회차', () {
    final group = ringLogGroups(
      [
        entry(1, monday7, RingLogKind.rang),
        entry(1, DateTime(2026, 10, 5, 7, 10), RingLogKind.autoStopped),
      ],
      [work],
    ).single;

    expect(group.end, RingLogKind.autoStopped);
    expect(group.endedAt, DateTime(2026, 10, 5, 7, 10));
    expect(group.snoozes, 0);
  });

  test('끔 기록이 없으면(울리는 중 · 앱이 죽음) 끝은 null', () {
    final group = ringLogGroups([entry(1, monday7, RingLogKind.rang)], [work]).single;

    expect(group.end, isNull);
    expect(group.endedAt, isNull);
  });

  test('건너뛴 회차는 그 회차 시각에 건너뜀으로 남는다', () {
    final group = ringLogGroups([entry(1, monday7, RingLogKind.skipped)], [work]).single;

    expect(group.skipped, isTrue);
    expect(group.at, monday7);
    expect(group.rangAt, isNull);
  });

  test('건너뛰었다가 취소해 울렸으면 울림이 이긴다', () {
    final group = ringLogGroups(
      [
        entry(1, monday7, RingLogKind.skipped),
        entry(1, monday7, RingLogKind.rang),
        entry(1, DateTime(2026, 10, 5, 7, 2), RingLogKind.stopped),
      ],
      [work],
    ).single;

    expect(group.skipped, isFalse);
    expect(group.rangAt, monday7);
  });

  test('지운 알람의 회차는 alarm 이 null 이고 alarmId 는 남는다', () {
    final group = ringLogGroups([entry(9, monday7, RingLogKind.rang)], [work]).single;

    expect(group.alarm, isNull);
    expect(group.alarmId, 9);
  });

  test('회차(packageId + 날짜)마다 나누고 최근 것이 먼저', () {
    final tuesday7 = DateTime(2026, 10, 6, 7);
    final monday630 = DateTime(2026, 10, 5, 6, 30);
    final groups = ringLogGroups(
      [
        entry(2, monday630, RingLogKind.rang),
        entry(1, monday7, RingLogKind.rang),
        entry(2, DateTime(2026, 10, 5, 6, 31), RingLogKind.stopped),
        entry(1, DateTime(2026, 10, 5, 7, 1), RingLogKind.stopped),
        entry(1, tuesday7, RingLogKind.rang),
      ],
      [work, gym],
    );

    expect(
      [for (final g in groups) (g.alarmId, g.at)],
      [(1, tuesday7), (1, monday7), (2, monday630)],
    );
    expect(groups.last.alarm, gym);
  });

  test('같은 packageId 라도 날짜가 다르면 다른 회차다(100일 주기)', () {
    final later = DateTime(2027, 1, 13, 7); // 100일 뒤 — 같은 index
    expect(pid(1, later), pid(1, monday7));

    final groups = ringLogGroups(
      [entry(1, monday7, RingLogKind.rang), entry(1, later, RingLogKind.rang)],
      [work],
    );

    expect(groups, hasLength(2));
  });

  test('자정을 넘긴 스누즈 · 끔도 같은 회차다', () {
    final sunday2355 = DateTime(2026, 10, 4, 23, 55);
    final late = Alarm(id: 1, hour: 23, minute: 55, label: '약', repeat: const {Weekday.sun});
    final groups = ringLogGroups(
      [
        entry(1, sunday2355, RingLogKind.rang),
        entry(1, DateTime(2026, 10, 4, 23, 56), RingLogKind.snoozed, occurrence: sunday2355),
        entry(1, DateTime(2026, 10, 5, 0, 6), RingLogKind.rang, occurrence: sunday2355),
        entry(1, DateTime(2026, 10, 5, 0, 7), RingLogKind.stopped, occurrence: sunday2355),
      ],
      [late],
    );

    expect(groups, [
      RingLogGroup(
        packageId: pid(1, sunday2355),
        alarm: late,
        at: sunday2355,
        rangAt: sunday2355,
        snoozes: 1,
        end: RingLogKind.stopped,
        endedAt: DateTime(2026, 10, 5, 0, 7),
        skipped: false,
      ),
    ]);
  });

  test('비면 빈 목록', () {
    expect(ringLogGroups(const [], [work]), isEmpty);
  });
}
