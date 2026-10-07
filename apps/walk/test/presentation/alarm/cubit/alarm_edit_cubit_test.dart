import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/entity/repeat_preset.dart';
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/one_shot_draft.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/cubit/alarm_edit_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_edit_state.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockCalendarAccess extends Mock implements HolidayCalendarAccess {}

class _FixedClock extends Clock {
  _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

const _chimeAlarm = Alarm(
  id: 3,
  hour: 6,
  minute: 30,
  repeat: {Weekday.mon},
  sound: AlarmSound.bundled(BundledAlarmSounds.chime),
);

const _monday = Alarm(hour: 7, minute: 0, repeat: {Weekday.mon});

const _tuned = Alarm(
  hour: 7,
  minute: 0,
  repeat: {Weekday.mon},
  volumePercent: 50,
  fadeSeconds: 30,
  snoozeMinutes: 10,
  snoozeLimit: 3,
  autoStopMinutes: 15,
  remindBefore: true,
);

void main() {
  final now = DateTime(2026, 9, 27, 23, 48);
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late AlarmPermissions permissions;
  late _MockCalendarAccess calendar;

  AlarmEditCubit build([Alarm? initial]) => AlarmEditCubit(
    useCase,
    permissions,
    _FixedClock(now),
    initial ?? Alarm.draft(),
    holidayCalendar: calendar,
  );

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
    calendar = _MockCalendarAccess();
    when(() => calendar.ensureIfReminding()).thenAnswer((_) async {});
  });

  test('새 알람은 isNew', () {
    expect(build().state.isNew, isTrue);
    expect(build(const Alarm(id: 3, hour: 6, minute: 30)).state.isNew, isFalse);
  });

  blocTest<AlarmEditCubit, AlarmEditState>(
    '시각 · 요일 · 라벨 · 무음 모드 체크를 바꾼다',
    build: build,
    act: (cubit) {
      cubit
        ..setTime(6, 30)
        ..toggleDay(Weekday.mon)
        ..toggleDay(Weekday.fri)
        ..toggleDay(Weekday.mon)
        ..setLabel('  출근 ')
        ..setSilentWhenRingerMuted(true);
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
          silentWhenRingerMuted: true,
        ),
      ),
    ],
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '알람음을 바꾸면 저장할 알람에 실린다',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (i) async => i.positionalArguments.single as Alarm,
      );
      return build(const Alarm(id: 3, hour: 6, minute: 30, repeat: {Weekday.mon}));
    },
    act: (cubit) async {
      cubit.setSound(const AlarmSound.bundled(BundledAlarmSounds.chime));
      await cubit.save();
    },
    expect: () => [
      const AlarmEditState(alarm: _chimeAlarm),
      const AlarmEditState(alarm: _chimeAlarm, busy: true),
      const AlarmEditState(alarm: _chimeAlarm),
    ],
    verify: (_) => verify(() => useCase.save(_chimeAlarm)).called(1),
  );

  test('쉬는 중에 저장하면 남은 시간은 기간 뒤 첫 회차까지다', () async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
    );
    // 월 9-28 을 쉬므로 다음 울림은 다음 주 월 10-5 07:00.
    when(() => useCase.pause()).thenAnswer(
      (_) async => AlarmPause(from: DateTime(2026, 9, 28), until: DateTime(2026, 9, 28)),
    );
    final cubit = build(_monday);

    expect(await cubit.save(), DateTime(2026, 10, 5, 7).difference(now));
    await cubit.close();
  });

  test('쉬는 기간을 읽지 못해도 저장은 성공하고 쉬지 않는 것으로 센다', () async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
    );
    when(() => useCase.pause()).thenThrow(StateError('prefs'));
    final cubit = build(_monday);

    expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
    await cubit.close();
  });

  blocTest<AlarmEditCubit, AlarmEditState>(
    '저장 → 권한 확인(거부돼도 계속) → 울릴 때까지 남은 시간',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
      );
      return build(_monday);
    },
    act: (cubit) async {
      expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
    },
    expect: () => const [
      AlarmEditState(alarm: _monday, busy: true),
      AlarmEditState(alarm: _monday),
    ],
    verify: (_) {
      verifyInOrder([
        () => useCase.save(_monday),
        () => notification.ensure(),
        () => exactAlarm.ensure(),
        () => calendar.ensureIfReminding(),
      ]);
    },
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '캘린더 권한 확인이 예외를 던져도 저장은 끝났으므로 남은 시간을 돌려준다',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
      );
      when(() => calendar.ensureIfReminding()).thenThrow(StateError('plugin'));
      return build(_monday);
    },
    act: (cubit) async {
      expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
    },
    skip: 2,
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '울림 설정(볼륨 · 점점 커지기 · 스누즈 간격 · 횟수 · 자동 멈춤 · 30분 전 알림)을 바꿔 저장한다',
    build: () {
      when(() => useCase.save(any())).thenAnswer((i) async => i.positionalArguments.single as Alarm);
      return build(_monday);
    },
    act: (cubit) async {
      cubit
        ..setVolumePercent(50)
        ..setFadeSeconds(30)
        ..setSnoozeMinutes(10)
        ..setSnoozeLimit(3)
        ..setAutoStopMinutes(15)
        ..setRemindBefore(true);
      await cubit.save();
      cubit
        ..setSnoozeLimit(null)
        ..setAutoStopMinutes(null);
    },
    expect: () => [
      const AlarmEditState(alarm: Alarm(hour: 7, minute: 0, repeat: {Weekday.mon}, volumePercent: 50)),
      const AlarmEditState(
        alarm: Alarm(hour: 7, minute: 0, repeat: {Weekday.mon}, volumePercent: 50, fadeSeconds: 30),
      ),
      AlarmEditState(
        alarm: _tuned.copyWith(snoozeLimit: null, autoStopMinutes: null, remindBefore: false),
      ),
      AlarmEditState(alarm: _tuned.copyWith(autoStopMinutes: null, remindBefore: false)),
      AlarmEditState(alarm: _tuned.copyWith(remindBefore: false)),
      const AlarmEditState(alarm: _tuned),
      const AlarmEditState(alarm: _tuned, busy: true),
      const AlarmEditState(alarm: _tuned),
      AlarmEditState(alarm: _tuned.copyWith(snoozeLimit: null)),
      AlarmEditState(alarm: _tuned.copyWith(snoozeLimit: null, autoStopMinutes: null)),
    ],
    verify: (_) => verify(() => useCase.save(_tuned)).called(1),
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '한 번 알람은 공휴일 미리 알림이 없으므로 캘린더 권한을 묻지 않는다',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
      );
      return build();
    },
    act: (cubit) async {
      cubit.addOffset(const Duration(hours: 1));
      await cubit.save();
    },
    verify: (_) {
      verify(() => exactAlarm.ensure()).called(1);
      verifyNever(() => calendar.ensureIfReminding());
    },
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '저장 뒤 권한 확인이 예외를 던져도 저장은 끝났으므로 남은 시간을 돌려준다',
    build: () {
      when(() => useCase.save(any())).thenAnswer(
        (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
      );
      when(() => notification.ensure()).thenThrow(StateError('plugin'));
      return build(_monday);
    },
    act: (cubit) async {
      expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
    },
    expect: () => const [
      AlarmEditState(alarm: _monday, busy: true),
      AlarmEditState(alarm: _monday),
    ],
    verify: (_) => verify(() => useCase.save(any())).called(1),
  );

  blocTest<AlarmEditCubit, AlarmEditState>(
    '저장이 실패하면 던지고 권한은 묻지 않는다',
    build: () {
      when(() => useCase.save(any())).thenThrow(StateError('full'));
      return build(_monday);
    },
    act: (cubit) => expectLater(cubit.save(), throwsStateError),
    expect: () => const [
      AlarmEditState(alarm: _monday, busy: true),
      AlarmEditState(alarm: _monday),
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

  group('한 번 알람', () {
    test('새 한 번 알람은 상대 모드 0 에서 시작하고 저장할 수 없다', () {
      final cubit = build();
      expect(cubit.state.draft, const OneShotDraft());
      expect(cubit.canSave(now), isFalse);
    });

    test('기존 한 번 알람의 oneShotAt 이 미래면 그 시각으로 고정해 연다', () {
      final at = DateTime(2026, 9, 28, 7);
      final cubit = build(Alarm(id: 3, hour: 7, minute: 0, oneShotAt: at));
      expect(cubit.state.draft, OneShotDraft(fixedAt: at));
      expect(cubit.canSave(now), isTrue);
    });

    blocTest<AlarmEditCubit, AlarmEditState>(
      '더하기 · 초기화 · 시각 고정',
      build: build,
      act: (cubit) => cubit
        ..addOffset(const Duration(hours: 1))
        ..addOffset(const Duration(minutes: 5))
        ..resetOffset()
        ..fixOneShotAt(7, 30)
        ..addOffset(const Duration(minutes: 10)),
      expect: () => [
        AlarmEditState(alarm: Alarm.draft(), draft: const OneShotDraft(offset: Duration(hours: 1))),
        AlarmEditState(
          alarm: Alarm.draft(),
          draft: const OneShotDraft(offset: Duration(hours: 1, minutes: 5)),
        ),
        AlarmEditState(alarm: Alarm.draft()),
        AlarmEditState(alarm: Alarm.draft(), draft: OneShotDraft(fixedAt: DateTime(2026, 9, 28, 7, 30))),
        AlarmEditState(alarm: Alarm.draft(), draft: OneShotDraft(fixedAt: DateTime(2026, 9, 28, 7, 40))),
      ],
    );

    test('1분 이상 더하면 저장할 수 있다', () {
      final cubit = build()..addOffset(const Duration(minutes: 1));
      expect(cubit.canSave(now), isTrue);
    });

    blocTest<AlarmEditCubit, AlarmEditState>(
      '저장은 지금 + offset 을 oneShotAt 으로, hour · minute 를 맞춰 넘긴다',
      build: () {
        when(() => useCase.save(any())).thenAnswer(
          (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
        );
        return build();
      },
      act: (cubit) async {
        cubit
          ..addOffset(const Duration(hours: 1))
          ..addOffset(const Duration(minutes: 10));
        expect(await cubit.save(), const Duration(hours: 1, minutes: 10));
      },
      skip: 2,
      verify: (_) => verify(
        () => useCase.save(Alarm(hour: 0, minute: 58, oneShotAt: DateTime(2026, 9, 28, 0, 58))),
      ).called(1),
    );

    blocTest<AlarmEditCubit, AlarmEditState>(
      '고정 모드: 기존 한 번 알람을 제목만 바꿔 저장하면 울릴 시각 · id 가 그대로 넘어간다',
      build: () {
        when(() => useCase.save(any())).thenAnswer((i) async => i.positionalArguments.single as Alarm);
        return build(Alarm(id: 3, hour: 7, minute: 0, oneShotAt: DateTime(2026, 9, 28, 7)));
      },
      act: (cubit) async {
        cubit.setLabel('낮잠');
        expect(await cubit.save(), const Duration(hours: 7, minutes: 12));
      },
      skip: 2,
      verify: (_) => verify(
        () => useCase.save(
          Alarm(id: 3, hour: 7, minute: 0, label: '낮잠', oneShotAt: DateTime(2026, 9, 28, 7)),
        ),
      ).called(1),
    );

    blocTest<AlarmEditCubit, AlarmEditState>(
      '고정 모드: 시각 휠로 고른 시각으로 저장한다',
      build: () {
        when(() => useCase.save(any())).thenAnswer(
          (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
        );
        return build();
      },
      act: (cubit) async {
        cubit.fixOneShotAt(7, 30);
        expect(await cubit.save(), const Duration(hours: 7, minutes: 42));
      },
      skip: 2,
      verify: (_) => verify(
        () => useCase.save(Alarm(hour: 7, minute: 30, oneShotAt: DateTime(2026, 9, 28, 7, 30))),
      ).called(1),
    );

    blocTest<AlarmEditCubit, AlarmEditState>(
      '저장할 수 없으면 save 는 던지고 use case 를 부르지 않는다',
      build: build,
      act: (cubit) => expectLater(cubit.save(), throwsStateError),
      verify: (_) => verifyNever(() => useCase.save(any())),
    );
  });

  group('반복 알람', () {
    blocTest<AlarmEditCubit, AlarmEditState>(
      '묶음을 고르면 요일 집합이 그 묶음이 된다',
      build: () => build(_monday),
      act: (cubit) => cubit
        ..applyPreset(RepeatPreset.weekend)
        ..applyPreset(RepeatPreset.everyday),
      expect: () => [
        AlarmEditState(alarm: _monday.copyWith(repeat: RepeatPreset.weekend.days)),
        AlarmEditState(alarm: _monday.copyWith(repeat: RepeatPreset.everyday.days)),
      ],
    );

    test('요일이 하나도 없으면 저장할 수 없다(한 번 알람으로 바뀌지 않는다)', () {
      final cubit = build(_monday);
      expect(cubit.canSave(now), isTrue);
      cubit.toggleDay(Weekday.mon);
      expect(cubit.state.alarm.repeat, isEmpty);
      expect(cubit.canSave(now), isFalse);
    });

    blocTest<AlarmEditCubit, AlarmEditState>(
      '요일이 없을 때 save 는 던진다',
      build: () => build(_monday),
      act: (cubit) async {
        cubit.toggleDay(Weekday.mon);
        await expectLater(cubit.save(), throwsStateError);
      },
      verify: (_) => verifyNever(() => useCase.save(any())),
    );
  });
}
