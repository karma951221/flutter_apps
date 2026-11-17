import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_ringing_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_ringing_state.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

void main() {
  const alarm = Alarm(id: 3, hour: 7, minute: 0, label: '출근');
  late _MockUseCase useCase;

  setUp(() {
    useCase = _MockUseCase();
    when(() => useCase.findByPackageId(312)).thenAnswer((_) async => alarm);
    when(() => useCase.snooze(312)).thenAnswer((_) async {});
    when(() => useCase.stop(312)).thenAnswer((_) async {});
    when(() => useCase.canSnooze(312)).thenAnswer((_) async => true);
  });

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    'load 는 울리는 회차의 알람을 찾는다',
    build: () => AlarmRingingCubit(useCase, 312),
    act: (cubit) => cubit.load(),
    expect: () => [const AlarmRingingState(alarm: alarm)],
  );

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    '스누즈 한도를 다 썼으면 canSnooze false',
    build: () {
      when(() => useCase.canSnooze(312)).thenAnswer((_) async => false);
      return AlarmRingingCubit(useCase, 312);
    },
    act: (cubit) => cubit.load(),
    expect: () => [const AlarmRingingState(alarm: alarm, canSnooze: false)],
  );

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    'canSnooze 를 읽지 못하면 스누즈를 남긴다(use case 가 늦은 스누즈를 막는다)',
    build: () {
      when(() => useCase.canSnooze(312)).thenThrow(StateError('plugin'));
      return AlarmRingingCubit(useCase, 312);
    },
    act: (cubit) => cubit.load(),
    expect: () => [const AlarmRingingState(alarm: alarm)],
  );

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    '처리 중에도 canSnooze 는 그대로',
    build: () => AlarmRingingCubit(useCase, 312),
    seed: () => const AlarmRingingState(alarm: alarm, canSnooze: false),
    act: (cubit) => cubit.stop(),
    expect: () => [
      const AlarmRingingState(alarm: alarm, canSnooze: false, busy: true),
      const AlarmRingingState(alarm: alarm, canSnooze: false),
    ],
  );

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    'snooze 는 그 회차를 미룬다',
    build: () => AlarmRingingCubit(useCase, 312),
    act: (cubit) => cubit.snooze(),
    expect: () => [
      const AlarmRingingState(busy: true),
      const AlarmRingingState(),
    ],
    verify: (_) => verify(() => useCase.snooze(312)).called(1),
  );

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    'stop 은 그 회차를 끈다',
    build: () => AlarmRingingCubit(useCase, 312),
    seed: () => const AlarmRingingState(alarm: alarm),
    act: (cubit) => cubit.stop(),
    expect: () => [
      const AlarmRingingState(alarm: alarm, busy: true),
      const AlarmRingingState(alarm: alarm),
    ],
    verify: (_) => verify(() => useCase.stop(312)).called(1),
  );
}
