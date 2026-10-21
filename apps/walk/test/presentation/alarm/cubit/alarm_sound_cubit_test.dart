import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/sound/alarm_sound_source.dart';
import 'package:walk/presentation/alarm/cubit/alarm_sound_cubit.dart';
import 'package:walk/presentation/alarm/cubit/alarm_sound_state.dart';

class _MockSoundSource extends Mock implements AlarmSoundSource {}

void main() {
  const bell = (title: 'Bell', uri: 'content://media/1');
  const dawn = (title: 'Dawn', uri: 'content://media/2');
  const copiedBell = AlarmSound.device(
    title: 'Bell',
    path: '/data/alarm_sounds/a.ogg',
  );
  late _MockSoundSource source;

  AlarmSoundCubit build([AlarmSound initial = const AlarmSound.system()]) =>
      AlarmSoundCubit(source, initial);

  setUpAll(() {
    registerFallbackValue(const AlarmSound.system());
    registerFallbackValue(bell);
  });
  setUp(() {
    source = _MockSoundSource();
    when(() => source.deviceRingtones()).thenAnswer((_) async => [bell, dawn]);
    when(
      () => source.preview(any(), uri: any(named: 'uri')),
    ).thenAnswer((_) async {});
    when(() => source.stopPreview()).thenAnswer((_) async {});
  });

  group('처음 선택은 현재 알람의 소리', () {
    test('시스템 · 내장 · 기기', () {
      expect(build().state.selected, const AlarmSoundChoice.system());
      expect(
        build(
          const AlarmSound.bundled(BundledAlarmSounds.chime),
        ).state.selected,
        const AlarmSoundChoice.bundled(BundledAlarmSounds.chime),
      );
      expect(
        build(copiedBell).state.selected,
        const AlarmSoundChoice.current(copiedBell),
      );
      expect(build().state.ringtones, const DeviceRingtones.loading());
      expect(build().state.importing, isFalse);
    });

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '목록을 읽으면 같은 제목의 기기 항목에 선택 표시가 옮겨 간다',
      build: () => build(copiedBell),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AlarmSoundState(
          selected: AlarmSoundChoice.device(bell),
          ringtones: DeviceRingtones.loaded([bell, dawn]),
        ),
      ],
    );

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '목록에 같은 제목이 없으면(원본 삭제) 현재 값 그대로',
      build: () =>
          build(const AlarmSound.device(title: 'Gone', path: '/x.ogg')),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AlarmSoundState(
          selected: AlarmSoundChoice.current(
            AlarmSound.device(title: 'Gone', path: '/x.ogg'),
          ),
          ringtones: DeviceRingtones.loaded([bell, dawn]),
        ),
      ],
    );

    test('목록을 읽는 동안 다른 것을 골랐으면 목록이 와도 선택을 바꾸지 않는다', () async {
      final ringtones = Completer<List<DeviceRingtone>>();
      when(() => source.deviceRingtones()).thenAnswer((_) => ringtones.future);
      final cubit = build(copiedBell);
      final loading = cubit.load();
      await cubit.select(const AlarmSoundChoice.system());
      ringtones.complete([bell, dawn]);
      await loading;
      expect(
        cubit.state,
        const AlarmSoundState(
          selected: AlarmSoundChoice.system(),
          ringtones: DeviceRingtones.loaded([bell, dawn]),
        ),
      );
    });
  });

  blocTest<AlarmSoundCubit, AlarmSoundState>(
    '기기 목록 읽기 실패 → failure',
    build: () {
      when(
        () => source.deviceRingtones(),
      ).thenThrow(const AlarmSoundException('list'));
      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const AlarmSoundState(
        selected: AlarmSoundChoice.system(),
        ringtones: DeviceRingtones.failure(),
      ),
    ],
  );

  group('탭하면 선택이 옮겨 가고 미리 듣는다', () {
    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '내장음 → 에셋 미리 듣기',
      build: build,
      act: (cubit) => cubit.select(
        const AlarmSoundChoice.bundled(BundledAlarmSounds.rising),
      ),
      expect: () => [
        const AlarmSoundState(
          selected: AlarmSoundChoice.bundled(BundledAlarmSounds.rising),
        ),
      ],
      verify: (_) => verify(
        () =>
            source.preview(const AlarmSound.bundled(BundledAlarmSounds.rising)),
      ).called(1),
    );

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '시스템 기본 → 시스템 미리 듣기',
      build: () => build(const AlarmSound.bundled(BundledAlarmSounds.beep)),
      act: (cubit) => cubit.select(const AlarmSoundChoice.system()),
      expect: () => [
        const AlarmSoundState(selected: AlarmSoundChoice.system()),
      ],
      verify: (_) =>
          verify(() => source.preview(const AlarmSound.system())).called(1),
    );

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '기기 알람음 → 복사 전이므로 uri 로 미리 듣기',
      build: build,
      act: (cubit) => cubit.select(const AlarmSoundChoice.device(dawn)),
      expect: () => [
        const AlarmSoundState(selected: AlarmSoundChoice.device(dawn)),
      ],
      verify: (_) =>
          verify(() => source.preview(any(), uri: dawn.uri)).called(1),
    );

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '미리 듣기가 실패해도 선택은 옮겨 가고 던지지 않는다',
      build: () {
        when(
          () => source.preview(any(), uri: any(named: 'uri')),
        ).thenThrow(const AlarmSoundException('preview'));
        return build();
      },
      act: (cubit) => cubit.select(
        const AlarmSoundChoice.bundled(BundledAlarmSounds.chime),
      ),
      expect: () => [
        const AlarmSoundState(
          selected: AlarmSoundChoice.bundled(BundledAlarmSounds.chime),
        ),
      ],
    );
  });

  group('선택(confirm)', () {
    test('시스템 · 내장음은 복사 없이 그대로 돌려준다', () async {
      final cubit = build()
        ..select(const AlarmSoundChoice.bundled(BundledAlarmSounds.chime));
      expect(
        await cubit.confirm(),
        const AlarmSound.bundled(BundledAlarmSounds.chime),
      );
      cubit.select(const AlarmSoundChoice.system());
      expect(await cubit.confirm(), const AlarmSound.system());
      verifyNever(() => source.import(any()));
    });

    test('목록에서 찾은 현재 기기 소리를 바꾸지 않고 선택하면 다시 복사하지 않고 그대로 돌려준다', () async {
      final cubit = build(copiedBell);
      await cubit.load();
      expect(cubit.state.selected, const AlarmSoundChoice.device(bell));
      expect(await cubit.confirm(), copiedBell);
      verifyNever(() => source.import(any()));
    });

    test('다른 줄을 골랐다가 현재 소리 줄로 돌아와도 다시 복사하지 않는다', () async {
      final cubit = build(copiedBell);
      await cubit.load();
      await cubit.select(const AlarmSoundChoice.device(dawn));
      await cubit.select(const AlarmSoundChoice.device(bell));
      expect(await cubit.confirm(), copiedBell);
      verifyNever(() => source.import(any()));
    });

    test('현재 소리와 다른 기기 줄을 고르면 복사한다', () async {
      when(() => source.import(dawn)).thenAnswer(
        (_) async => const AlarmSound.device(
          title: 'Dawn',
          path: '/data/alarm_sounds/b.ogg',
        ),
      );
      final cubit = build(copiedBell);
      await cubit.load();
      await cubit.select(const AlarmSoundChoice.device(dawn));
      expect(
        await cubit.confirm(),
        const AlarmSound.device(
          title: 'Dawn',
          path: '/data/alarm_sounds/b.ogg',
        ),
      );
      verify(() => source.import(dawn)).called(1);
    });

    test('목록에 없는 현재 기기 소리는 그대로 돌려준다', () async {
      final cubit = build(copiedBell);
      expect(await cubit.confirm(), copiedBell);
      verifyNever(() => source.import(any()));
    });

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '기기 알람음은 복사(import) 한 결과를 돌려주고, 그동안 importing',
      build: () {
        when(() => source.import(bell)).thenAnswer((_) async => copiedBell);
        return build();
      },
      act: (cubit) async {
        cubit.select(const AlarmSoundChoice.device(bell));
        expect(await cubit.confirm(), copiedBell);
      },
      expect: () => [
        const AlarmSoundState(selected: AlarmSoundChoice.device(bell)),
        const AlarmSoundState(
          selected: AlarmSoundChoice.device(bell),
          importing: true,
        ),
        const AlarmSoundState(selected: AlarmSoundChoice.device(bell)),
      ],
    );

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '복사가 실패하면 던지고 importing 을 푼다',
      build: () {
        when(
          () => source.import(bell),
        ).thenThrow(const AlarmSoundException('import'));
        return build();
      },
      act: (cubit) async {
        cubit.select(const AlarmSoundChoice.device(bell));
        await expectLater(cubit.confirm(), throwsA(isA<AlarmSoundException>()));
      },
      expect: () => [
        const AlarmSoundState(selected: AlarmSoundChoice.device(bell)),
        const AlarmSoundState(
          selected: AlarmSoundChoice.device(bell),
          importing: true,
        ),
        const AlarmSoundState(selected: AlarmSoundChoice.device(bell)),
      ],
    );

    blocTest<AlarmSoundCubit, AlarmSoundState>(
      '복사 중에는 다른 줄을 골라도 무시한다',
      build: () {
        when(() => source.import(bell)).thenAnswer((_) async => copiedBell);
        return build();
      },
      act: (cubit) async {
        cubit.select(const AlarmSoundChoice.device(bell));
        final importing = cubit.confirm();
        cubit.select(const AlarmSoundChoice.system());
        expect(await importing, copiedBell);
      },
      expect: () => [
        const AlarmSoundState(selected: AlarmSoundChoice.device(bell)),
        const AlarmSoundState(
          selected: AlarmSoundChoice.device(bell),
          importing: true,
        ),
        const AlarmSoundState(selected: AlarmSoundChoice.device(bell)),
      ],
    );
  });

  test('pausePreview 는 선택은 두고 미리 듣기만 멈춘다', () async {
    final cubit = build();
    await cubit.select(
      const AlarmSoundChoice.bundled(BundledAlarmSounds.chime),
    );
    await cubit.pausePreview();
    verify(() => source.stopPreview()).called(1);
    expect(
      cubit.state.selected,
      const AlarmSoundChoice.bundled(BundledAlarmSounds.chime),
    );
  });

  test('닫으면 미리 듣기를 멈춘다', () async {
    await build().close();
    verify(() => source.stopPreview()).called(1);
  });
}
