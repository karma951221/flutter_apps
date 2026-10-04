import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_edit_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_edit_state.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _FixedClock extends Clock {
  _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime(2026, 9, 27, 23, 48);
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late AlarmPermissions permissions;

  AlarmEditCubit build([Alarm? initial]) =>
      AlarmEditCubit(useCase, permissions, _FixedClock(now), initial ?? Alarm.draft());

  setUpAll(() => registerFallbackValue(Alarm.draft()));
  setUp(() {
    useCase = _MockUseCase();
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    permissions = AlarmPermissions(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: _MockRequester(),
    );
    when(() => notification.ensure()).thenAnswer((_) async => PermissionStatus.denied);
    when(() => exactAlarm.ensure()).thenAnswer((_) async => PermissionStatus.granted);
  });

  test('새 알람은 isNew', () {
    expect(build().state.isNew, isTrue);
    expect(build(const Alarm(id: 3, hour: 6, minute: 30)).state.isNew, isFalse);
  });

  blocTest<AlarmEditCubit, AlarmEditState>(
    '시각 · 요일 · 라벨 · 진동을 바꾼다',
    build: build,
    act: (cubit) {
      cubit
        ..setTime(6, 30)
        ..toggleDay(Weekday.mon)
        ..toggleDay(Weekday.fri)
        ..toggleDay(Weekday.mon)
        ..setLabel('  출근 ')
        ..setVibrate(false);
    },
    expect: () => [
      const AlarmEditState(alarm: Alarm(hour: 6, minute: 30)),
      const AlarmEditState(alarm: Alarm(hour: 6, minute: 30, repeat: {Weekday.mon})),
      const AlarmEditState(
        alarm: Alarm(hour: 6, minute: 30, repeat: {Weekday.mon, Weekday.fri}),
      ),
      const AlarmEditState(alarm: Alarm(hour: 6, minute: 30, repeat: {Weekday.fri})),
      const AlarmEditState(
        alarm: Alarm(hour: 6, minute: 30, repeat: {Weekday.fri}, label: '출근'),
      ),
      const AlarmEditState(
        alarm: Alarm(
          hour: 6,
          minute: 30,
          repeat: {Weekday.fri},
          label: '출근',
          vibrate: false,
        ),
      ),
    ],
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '저장 → 권한 확인(거부돼도 계속) → 울릴 때까지 남은 시간',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (_) async => Alarm(id: 1, hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 28, 7)),
      );
      return build();
    },
    act: (cubit) async {
      expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
    },
    expect: () => [
      AlarmEditState(alarm: Alarm.draft(), busy: true),
      AlarmEditState(alarm: Alarm.draft()),
    ],
    verify: (_) {
      verifyInOrder([
        () => useCase.save(Alarm.draft()),
        () => notification.ensure(),
        () => exactAlarm.ensure(),
      ]);
    },
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '저장 뒤 권한 확인이 예외를 던져도 저장은 끝났으므로 남은 시간을 돌려준다',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (_) async => Alarm(id: 1, hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 28, 7)),
      );
      when(() => notification.ensure()).thenThrow(StateError('plugin'));
      return build();
    },
    act: (cubit) async {
      expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
    },
    expect: () => [
      AlarmEditState(alarm: Alarm.draft(), busy: true),
      AlarmEditState(alarm: Alarm.draft()),
    ],
    verify: (_) => verify(() => useCase.save(any())).called(1),
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '저장이 실패하면 던지고 권한은 묻지 않는다',
    build: () {
      when(() => useCase.save(any())).thenThrow(StateError('full'));
      return build();
    },
    act: (cubit) => expectLater(cubit.save(), throwsStateError),
    expect: () => [
      AlarmEditState(alarm: Alarm.draft(), busy: true),
      AlarmEditState(alarm: Alarm.draft()),
    ],
    verify: (_) => verifyNever(() => notification.ensure()),
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '삭제',
    build: () {
      when(() => useCase.delete(3)).thenAnswer((_) async {});
      return build(const Alarm(id: 3, hour: 6, minute: 30));
    },
    act: (cubit) => cubit.delete(),
    verify: (_) => verify(() => useCase.delete(3)).called(1),
  );
}
