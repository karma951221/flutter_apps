import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_trigger.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_list_state.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _FixedClock extends Clock {
  _FixedClock(this.value);
  final DateTime value;
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

  AlarmListCubit build() => AlarmListCubit(useCase, permissions, _FixedClock(now));

  setUp(() {
    useCase = _MockUseCase();
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    permissions = AlarmPermissions(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: _MockRequester(),
    );
    when(() => useCase.list()).thenAnswer((_) async => [seven, off]);
    when(() => useCase.next()).thenAnswer(
      (_) async => AlarmTrigger(packageId: 100, alarmId: 1, at: DateTime(2026, 9, 28, 7)),
    );
    when(() => notification.check()).thenAnswer((_) async => PermissionStatus.granted);
    when(() => exactAlarm.check()).thenAnswer((_) async => PermissionStatus.granted);
    when(() => notification.ensure()).thenAnswer((_) async => PermissionStatus.granted);
    when(() => exactAlarm.ensure()).thenAnswer((_) async => PermissionStatus.granted);
  });

  test('처음은 loading', () {
    expect(build().state, const AlarmListState.loading());
  });

  blocTest<AlarmListCubit, AlarmListState>(
    'load 는 목록 · 다음 알람까지 · 권한을 담는다',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const AlarmListState.loaded(
        alarms: [seven, off],
        untilNext: Duration(hours: 7, minutes: 12),
      ),
    ],
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '켜진 알람이 없으면 untilNext 는 null, 권한이 없으면 canRing false',
    build: () {
      when(() => useCase.next()).thenAnswer((_) async => null);
      when(() => exactAlarm.check()).thenAnswer((_) async => PermissionStatus.denied);
      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const AlarmListState.loaded(alarms: [seven, off], canRing: false),
    ],
  );

  blocTest<AlarmListCubit, AlarmListState>(
    '켜면 먼저 스위치를 반영하고, 저장 뒤 권한을 확인하고 남은 시간을 돌려준다',
    build: () {
      when(() => useCase.toggle(2, enabled: true)).thenAnswer(
        (_) async => off.copyWith(enabled: true, oneShotAt: DateTime(2026, 9, 28, 8)),
      );
      return build();
    },
    seed: () => const AlarmListState.loaded(alarms: [seven, off]),
    act: (cubit) async {
      final untilRing = await cubit.toggle(off, enabled: true);
      expect(untilRing, const Duration(hours: 8, minutes: 12));
    },
    expect: () => [
      AlarmListState.loaded(alarms: [seven, off.copyWith(enabled: true)]),
      const AlarmListState.loaded(
        alarms: [seven, off],
        untilNext: Duration(hours: 7, minutes: 12),
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
    '끄면 권한을 묻지 않고 null',
    build: () {
      when(() => useCase.toggle(1, enabled: false))
          .thenAnswer((_) async => seven.copyWith(enabled: false));
      return build();
    },
    seed: () => const AlarmListState.loaded(alarms: [seven, off]),
    act: (cubit) async => expect(await cubit.toggle(seven, enabled: false), isNull),
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
    seed: () => const AlarmListState.loaded(alarms: [seven, off]),
    act: (cubit) async {
      await expectLater(cubit.toggle(seven, enabled: false), throwsStateError);
    },
    expect: () => [
      AlarmListState.loaded(alarms: [seven.copyWith(enabled: false), off]),
      const AlarmListState.loaded(
        alarms: [seven, off],
        untilNext: Duration(hours: 7, minutes: 12),
      ),
    ],
  );
}
