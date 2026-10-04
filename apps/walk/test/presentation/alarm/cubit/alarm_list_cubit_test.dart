import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_state.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MutableClock extends Clock {
  _MutableClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime(2026, 9, 27, 23, 48); // 일요일
  const seven = Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon});
  const off = Alarm(id: 2, hour: 8, minute: 0, enabled: false);
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late AlarmPermissions permissions;
  late _MutableClock clock;
  final sevenAt = DateTime(2026, 9, 28, 7);

  AlarmListCubit build() => AlarmListCubit(useCase, permissions, clock);

  AlarmListState loaded(
    List<Alarm> alarms, {
    Map<int, DateTime>? nextAt,
    DateTime? at,
    bool canRing = true,
  }) => AlarmListState.loaded(
    alarms: alarms,
    nextAt: nextAt ?? {1: sevenAt},
    now: at ?? now,
    canRing: canRing,
  );

  setUp(() {
    useCase = _MockUseCase();
    clock = _MutableClock(now);
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    permissions = AlarmPermissions(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: _MockRequester(),
    );
    when(() => useCase.list()).thenAnswer((_) async => [seven, off]);
    when(() => useCase.nextRings()).thenAnswer((_) async => {1: sevenAt});
    when(() => notification.check()).thenAnswer((_) async => PermissionStatus.granted);
    when(() => exactAlarm.check()).thenAnswer((_) async => PermissionStatus.granted);
    when(() => notification.ensure()).thenAnswer((_) async => PermissionStatus.granted);
    when(() => exactAlarm.ensure()).thenAnswer((_) async => PermissionStatus.granted);
  });

  test('처음은 loading', () {
    expect(build().state, const AlarmListState.loading());
  });

  blocTest<AlarmListCubit, AlarmListState>(
    'load 는 목록 · 알람별 다음 울림 · 기준 시각 · 권한을 담는다',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [loaded([seven, off])],
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '켜진 알람이 없으면 nextAt 은 비고, 권한이 없으면 canRing false',
    build: () {
      when(() => useCase.nextRings()).thenAnswer((_) async => {});
      when(() => exactAlarm.check()).thenAnswer((_) async => PermissionStatus.denied);
      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      loaded([seven, off], nextAt: {}, canRing: false),
    ],
  );

  group('읽기 실패', () {
    blocTest<AlarmListCubit, AlarmListState>(
      '목록을 읽지 못하면 loading 에 머물지 않고 failure — load 는 던지지 않는다',
      build: () {
        when(() => useCase.list()).thenThrow(const FormatException('corrupt'));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [const AlarmListState.failure()],
    );

    blocTest<AlarmListCubit, AlarmListState>(
      '권한 확인(canRing)이 예외여도 목록은 보이고, 울릴지 모르니 경고(canRing false)',
      build: () {
        when(() => notification.check()).thenThrow(StateError('plugin'));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [loaded([seven, off], canRing: false)],
    );

    blocTest<AlarmListCubit, AlarmListState>(
      '다음 울림을 읽지 못해도 목록은 보인다(nextAt 비움)',
      build: () {
        when(() => useCase.nextRings()).thenThrow(StateError('scheduler'));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [loaded([seven, off], nextAt: {})],
    );

    blocTest<AlarmListCubit, AlarmListState>(
      '실패 뒤 다시 load 하면 목록으로 돌아온다',
      build: () {
        when(() => useCase.list()).thenThrow(const FormatException('corrupt'));
        return build();
      },
      act: (cubit) async {
        await cubit.load();
        when(() => useCase.list()).thenAnswer((_) async => [seven, off]);
        await cubit.load();
      },
      expect: () => [const AlarmListState.failure(), loaded([seven, off])],
    );
  });

  group('tick', () {
    blocTest<AlarmListCubit, AlarmListState>(
      '기준 시각만 옮기고 저장소 · 예약은 읽지 않는다',
      build: build,
      seed: () => loaded([seven, off]),
      act: (cubit) {
        clock.value = DateTime(2026, 9, 27, 23, 49);
        return cubit.tick();
      },
      expect: () => [
        loaded([seven, off], at: DateTime(2026, 9, 27, 23, 49)),
      ],
      verify: (_) {
        verifyNever(() => useCase.list());
        verifyNever(() => useCase.nextRings());
        verifyNever(() => notification.check());
      },
    );

    blocTest<AlarmListCubit, AlarmListState>(
      '울릴 시각이 지났으면 다시 읽어 다음 회차로 넘긴다',
      build: () {
        when(() => useCase.nextRings())
            .thenAnswer((_) async => {1: DateTime(2026, 10, 5, 7)});
        return build();
      },
      seed: () => loaded([seven, off]),
      act: (cubit) {
        clock.value = sevenAt;
        return cubit.tick();
      },
      expect: () => [
        loaded([seven, off], nextAt: {1: DateTime(2026, 10, 5, 7)}, at: sevenAt),
      ],
      verify: (_) => verify(() => useCase.nextRings()).called(1),
    );

    blocTest<AlarmListCubit, AlarmListState>(
      '아직 읽지 않았으면(loading) 아무것도 하지 않는다',
      build: build,
      act: (cubit) => cubit.tick(),
      expect: () => <AlarmListState>[],
    );
  });

  blocTest<AlarmListCubit, AlarmListState>(
    '켜면 먼저 스위치를 반영하고, 저장 뒤 권한을 확인하고 남은 시간을 돌려준다',
    build: () {
      final on = off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 8));
      when(() => useCase.toggle(2, enabled: true)).thenAnswer((_) async {
        when(() => useCase.list()).thenAnswer((_) async => [seven, on]);
        when(() => useCase.nextRings())
            .thenAnswer((_) async => {1: sevenAt, 2: DateTime(2026, 9, 28, 8)});
        return on;
      });
      return build();
    },
    seed: () => loaded([seven, off]),
    act: (cubit) async {
      final untilRing = await cubit.toggle(off, enabled: true);
      expect(untilRing, const Duration(hours: 8, minutes: 12));
    },
    expect: () => [
      // 스위치만 먼저 움직이고, 남은 시간(nextAt)은 저장 뒤 다시 읽을 때 바뀐다.
      loaded([seven, off.copyWith(enabled: true)]),
      loaded(
        [seven, off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 8))],
        nextAt: {1: sevenAt, 2: DateTime(2026, 9, 28, 8)},
      ),
    ],
    verify: (_) {
      verifyInOrder([
        () => useCase.toggle(2, enabled: true),
        () => notification.ensure(),
        () => exactAlarm.ensure(),
      ]);
    },
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '켠 뒤 권한 확인이 예외여도 토글은 성공으로 끝난다',
    build: () {
      final on = off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 8));
      when(() => useCase.toggle(2, enabled: true)).thenAnswer((_) async {
        when(() => useCase.list()).thenAnswer((_) async => [seven, on]);
        when(() => useCase.nextRings())
            .thenAnswer((_) async => {1: sevenAt, 2: DateTime(2026, 9, 28, 8)});
        return on;
      });
      when(() => notification.ensure()).thenThrow(StateError('plugin'));
      return build();
    },
    seed: () => loaded([seven, off]),
    act: (cubit) async {
      expect(
        await cubit.toggle(off, enabled: true),
        const Duration(hours: 8, minutes: 12),
      );
    },
    expect: () => [
      loaded([seven, off.copyWith(enabled: true)]),
      loaded(
        [seven, off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 8))],
        nextAt: {1: sevenAt, 2: DateTime(2026, 9, 28, 8)},
      ),
    ],
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '끄면 권한을 묻지 않고 null',
    build: () {
      when(() => useCase.toggle(1, enabled: false)).thenAnswer((_) async {
        when(() => useCase.list()).thenAnswer((_) async => [seven.copyWith(enabled: false), off]);
        when(() => useCase.nextRings()).thenAnswer((_) async => {});
        return seven.copyWith(enabled: false);
      });
      return build();
    },
    seed: () => loaded([seven, off]),
    act: (cubit) async => expect(await cubit.toggle(seven, enabled: false), isNull),
    expect: () => [
      loaded([seven.copyWith(enabled: false), off]),
      loaded([seven.copyWith(enabled: false), off], nextAt: {}),
    ],
    verify: (_) {
      verifyNever(() => notification.ensure());
      verifyNever(() => exactAlarm.ensure());
    },
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '저장이 실패하면 던지고 목록을 다시 읽어 스위치를 되돌린다',
    build: () {
      when(() => useCase.toggle(1, enabled: false)).thenThrow(StateError('x'));
      return build();
    },
    seed: () => loaded([seven, off]),
    act: (cubit) async {
      await expectLater(cubit.toggle(seven, enabled: false), throwsStateError);
    },
    expect: () => [
      loaded([seven.copyWith(enabled: false), off]),
      loaded([seven, off]),
    ],
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '켜기가 실패해도 스위치를 되돌린다',
    build: () {
      when(() => useCase.toggle(2, enabled: true)).thenThrow(StateError('x'));
      return build();
    },
    seed: () => loaded([seven, off]),
    act: (cubit) async {
      await expectLater(cubit.toggle(off, enabled: true), throwsStateError);
    },
    expect: () => [
      loaded([seven, off.copyWith(enabled: true)]),
      loaded([seven, off]),
    ],
    verify: (_) => verifyNever(() => notification.ensure()),
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '저장도 다시 읽기도 실패하면 저장 오류를 던지고, 낙관적 스위치 대신 failure 로 끝난다',
    build: () {
      when(() => useCase.toggle(1, enabled: false)).thenAnswer((_) async {
        when(() => useCase.list()).thenThrow(const FormatException('corrupt'));
        throw StateError('save');
      });
      return build();
    },
    seed: () => loaded([seven, off]),
    act: (cubit) async {
      await expectLater(cubit.toggle(seven, enabled: false), throwsStateError);
    },
    expect: () => [
      loaded([seven.copyWith(enabled: false), off]),
      const AlarmListState.failure(),
    ],
  );
}
