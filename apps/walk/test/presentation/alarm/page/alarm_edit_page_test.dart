import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/sound/alarm_sound_source.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/format/alarm_format.dart';
import 'package:walk/presentation/alarm/page/alarm_edit_page.dart';
import 'package:walk/presentation/alarm/page/alarm_sound_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockSoundSource extends Mock implements AlarmSoundSource {}

class _FixedClock extends Clock {
  @override
  DateTime now() => DateTime(2026, 9, 27, 23, 48);
}

void main() {
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late _MockSoundSource soundSource;

  setUpAll(() {
    registerFallbackValue(Alarm.draft());
    registerFallbackValue(const AlarmSound.system());
  });
  setUp(() {
    useCase = _MockUseCase();
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    when(notification.ensure).thenAnswer((_) async => PermissionStatus.granted);
    when(exactAlarm.ensure).thenAnswer((_) async => PermissionStatus.granted);
    soundSource = _MockSoundSource();
    when(soundSource.deviceRingtones).thenAnswer((_) async => []);
    when(() => soundSource.preview(any(), uri: any(named: 'uri'))).thenAnswer((_) async {});
    when(soundSource.stopPreview).thenAnswer((_) async {});
    getIt
      ..registerSingleton<AlarmSoundSource>(soundSource)
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<AlarmPermissions>(
        AlarmPermissions(
          notification: notification,
          exactAlarm: exactAlarm,
          fullScreenIntent: _MockRequester(),
        ),
      )
      ..registerSingleton<Clock>(_FixedClock());
  });
  tearDown(getIt.reset);

  /// 편집 화면을 띄우고, 닫힐 때의 결과를 [results] 에 모은다.
  Future<List<Duration?>> pump(WidgetTester tester, Alarm initial) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <Duration?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<Duration>(
                MaterialPageRoute(builder: (_) => AlarmEditPage(initial: initial)),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('새 알람: 요일 · 라벨을 고르고 저장하면 use case → 권한 → 남은 시간으로 닫힌다', (
    tester,
  ) async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
    );
    final results = await pump(tester, Alarm.draft());

    expect(find.text('새 알람'), findsOneWidget);
    expect(find.text('삭제'), findsNothing);
    await tester.tap(find.text('월'));
    await tester.enterText(find.byType(TextField), '출근');
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = verify(() => useCase.save(captureAny())).captured.single as Alarm;
    expect(saved.repeat, {Weekday.mon});
    expect(saved.label, '출근');
    expect(saved.hour, 7);
    verifyInOrder([notification.ensure, exactAlarm.ensure]);
    // 일요일 23:48 → 월요일 07:00
    expect(results, [const Duration(hours: 7, minutes: 12)]);
    expect(find.byType(AlarmEditPage), findsNothing);
  });

  testWidgets('저장이 실패하면 머물고 오류 스낵바', (tester) async {
    when(() => useCase.save(any())).thenThrow(StateError('full'));
    await pump(tester, Alarm.draft());

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditPage), findsOneWidget);
    expect(find.text('알람을 저장하지 못했어요'), findsOneWidget);
  });

  testWidgets('권한 확인이 실패해도 편집 화면은 닫히고, 다시 저장해 알람이 둘이 되지 않는다', (
    tester,
  ) async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
    );
    when(notification.ensure).thenThrow(StateError('plugin'));
    final results = await pump(tester, Alarm.draft());

    await tester.tap(find.text('월'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditPage), findsNothing);
    expect(find.text('알람을 저장하지 못했어요'), findsNothing);
    expect(results, [const Duration(hours: 7, minutes: 12)]);
    verify(() => useCase.save(any())).called(1);
  });

  testWidgets('저장 중에는 저장 버튼이 잠겨 두 번 저장되지 않는다', (tester) async {
    final saving = Completer<Alarm>();
    when(() => useCase.save(any())).thenAnswer((_) => saving.future);
    await pump(tester, Alarm.draft());

    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    saving.complete(const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon}));
    await tester.pumpAndSettle();

    verify(() => useCase.save(any())).called(1);
    expect(find.byType(AlarmEditPage), findsNothing);
  });

  testWidgets('시각 휠을 돌리면 그 시각으로 저장한다', (tester) async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1),
    );
    await pump(tester, Alarm.draft());

    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(DateTime(2000, 1, 1, 6, 45));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = verify(() => useCase.save(captureAny())).captured.single as Alarm;
    expect((saved.hour, saved.minute), (6, 45));
  });

  testWidgets('기존 알람 저장은 id · 라벨 · 반복을 유지한다', (tester) async {
    const existing = Alarm(id: 3, hour: 6, minute: 30, label: '출근', repeat: {Weekday.mon});
    when(() => useCase.save(any())).thenAnswer(
      (i) async => i.positionalArguments.single as Alarm,
    );
    await pump(tester, existing);

    expect(find.widgetWithText(TextField, '출근'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = verify(() => useCase.save(captureAny())).captured.single as Alarm;
    expect(saved.id, 3);
    expect(saved.label, '출근');
    expect(saved.repeat, {Weekday.mon});
    expect((saved.hour, saved.minute), (6, 30));
  });

  testWidgets('알람음 줄은 저장 버튼 위에 현재 이름을 보이고, 진동 토글은 없다', (tester) async {
    await pump(
      tester,
      const Alarm(id: 3, hour: 6, minute: 30, sound: AlarmSound.bundled(BundledAlarmSounds.chime)),
    );

    expect(find.text('알람음'), findsOneWidget);
    expect(find.text('차임'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('알람음')).dy,
      lessThan(tester.getTopLeft(find.text('저장')).dy),
    );
    expect(find.text('진동'), findsNothing);
  });

  testWidgets('새 알람의 알람음은 시스템 기본', (tester) async {
    await pump(tester, Alarm.draft());

    expect(find.text('시스템 기본'), findsOneWidget);
  });

  testWidgets('알람음 줄 → 선택 화면에서 고르면 줄에 반영되고 그 소리로 저장한다', (tester) async {
    when(() => useCase.save(any())).thenAnswer(
      (i) async => i.positionalArguments.single as Alarm,
    );
    await pump(tester, const Alarm(id: 3, hour: 6, minute: 30));

    await tester.tap(find.text('알람음'));
    await tester.pumpAndSettle();
    expect(find.byType(AlarmSoundPage), findsOneWidget);
    await tester.tap(find.text('비프'));
    await tester.pump();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmSoundPage), findsNothing);
    expect(find.text('비프'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = verify(() => useCase.save(captureAny())).captured.single as Alarm;
    expect(saved.sound, const AlarmSound.bundled(BundledAlarmSounds.beep));
  });

  testWidgets('선택 화면에서 그냥 돌아오면 알람음은 그대로', (tester) async {
    await pump(tester, const Alarm(id: 3, hour: 6, minute: 30));

    await tester.tap(find.text('알람음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('비프'));
    await tester.pump();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(find.text('시스템 기본'), findsOneWidget);
    expect(find.text('비프'), findsNothing);
  });

  testWidgets('편집: 삭제는 확인 뒤 지우고 결과 없이 닫힌다', (tester) async {
    when(() => useCase.delete(3)).thenAnswer((_) async {});
    final results = await pump(tester, const Alarm(id: 3, hour: 6, minute: 30));

    expect(find.text('알람 편집'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('알람을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();

    verify(() => useCase.delete(3)).called(1);
    expect(results, [null]);
  });

  testWidgets('좁은 화면(320dp)에서도 요일 토글 7개가 한 줄에 오버플로 없이 들어간다', (tester) async {
    await pump(tester, Alarm.draft());
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final weekdayLabels = Weekday.values
        .map((day) => AlarmFormat.weekday('ko', day))
        .toList();
    final positions = weekdayLabels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toSet();
    expect(positions, hasLength(1), reason: '요일 토글은 모두 같은 줄(같은 dy)에 있어야 한다');
  });
}
