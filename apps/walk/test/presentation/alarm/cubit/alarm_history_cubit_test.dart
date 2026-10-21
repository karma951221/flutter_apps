import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/ring_log.dart';
import 'package:walk/domain/alarm/ring_log/ring_log_source.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_history_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_history_state.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRingLog extends Mock implements RingLogSource {}

class _FixedClock extends Clock {
  _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  // 2026-10-07 수요일 정오.
  final now = DateTime(2026, 10, 7, 12);
  const work = Alarm(
    id: 1,
    hour: 7,
    minute: 0,
    label: '출근',
    repeat: {Weekday.mon},
  );
  final rang = RingLogEntry(
    at: DateTime(2026, 10, 7, 7),
    packageId: 100,
    kind: RingLogKind.rang,
  );
  // 내일 회차를 미리 건너뛴 기록 — 아직 오지 않은 회차라 보이지 않는다.
  final futureSkip = RingLogEntry(
    at: DateTime(2026, 10, 8, 7),
    packageId: 101,
    kind: RingLogKind.skipped,
  );
  late _MockUseCase useCase;
  late _MockRingLog ringLog;

  setUp(() {
    useCase = _MockUseCase();
    ringLog = _MockRingLog();
    when(() => useCase.list()).thenAnswer((_) async => [work]);
  });

  AlarmHistoryCubit build() =>
      AlarmHistoryCubit(ringLog, useCase, _FixedClock(now));

  blocTest<AlarmHistoryCubit, AlarmHistoryState>(
    '최근 30일 기록을 회차로 묶어 싣는다(아직 오지 않은 회차는 뺀다)',
    setUp: () => when(
      () => ringLog.read(since: any(named: 'since')),
    ).thenAnswer((_) async => [rang, futureSkip]),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      AlarmHistoryState.loaded(groups: ringLogGroups([rang], [work]), now: now),
    ],
    verify: (_) =>
        verify(() => ringLog.read(since: DateTime(2026, 9, 7))).called(1),
  );

  blocTest<AlarmHistoryCubit, AlarmHistoryState>(
    '회차가 지났지만 아직 sync 가 기록하지 않은 건너뛰기(skippedAt)도 건너뜀으로 싣는다',
    setUp: () {
      when(
        () => ringLog.read(since: any(named: 'since')),
      ).thenAnswer((_) async => [rang]);
      when(() => useCase.list()).thenAnswer(
        (_) async => [
          work.copyWith(skippedAt: DateTime(2026, 10, 7, 7)),
          const Alarm(
            id: 2,
            hour: 9,
            minute: 0,
            repeat: {Weekday.thu},
          ).copyWith(
            skippedAt: DateTime(2026, 10, 8, 9), // 아직 오지 않았다
          ),
        ],
      );
    },
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      final groups = (cubit.state as AlarmHistoryLoaded).groups;
      final skippedGroups = groups.where((g) => g.skipped);
      expect(skippedGroups.map((g) => (g.alarmId, g.at)), [
        (1, DateTime(2026, 10, 7, 7)),
      ]);
    },
  );

  blocTest<AlarmHistoryCubit, AlarmHistoryState>(
    '읽기에 실패하면 failure, 다시 읽으면 loading 을 거쳐 돌아온다',
    setUp: () => when(
      () => ringLog.read(since: any(named: 'since')),
    ).thenThrow(StateError('채널 실패')),
    build: build,
    act: (cubit) async {
      await cubit.load();
      when(
        () => ringLog.read(since: any(named: 'since')),
      ).thenAnswer((_) async => []);
      await cubit.load();
    },
    expect: () => [
      const AlarmHistoryState.failure(),
      const AlarmHistoryState.loading(),
      AlarmHistoryState.loaded(groups: const [], now: now),
    ],
  );
}
