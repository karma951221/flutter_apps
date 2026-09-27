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
  });

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    'load 는 울리는 회차의 알람을 찾는다',
    build: () => AlarmRingingCubit(useCase, 312),
    act: (cubit) => cubit.load(),
    expect: () => [const AlarmRingingState(alarm: alarm)],
  );

  blocTest<AlarmRingingCubit, AlarmRingingState>(
    'snooze 는 그 회차를 미룬다',
    build: () => AlarmRingingCubit(useCase, 312),
    act: (cubit) => cubit.snooze(),
    expect: () => [const AlarmRingingState(busy: true), const AlarmRingingState()],
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
