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
import 'package:walk/domain/alarm/holiday/holiday_calendar_access.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/sound/alarm_sound_source.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/presentation/alarm/format/alarm_format.dart';
import 'package:walk/presentation/alarm/page/alarm_edit_page.dart';
import 'package:walk/presentation/alarm/page/alarm_sound_page.dart';

class _MockUseCase extends Mock implements AlarmUseCase {}

class _MockRequester extends Mock implements PermissionRequester {}

class _MockSoundSource extends Mock implements AlarmSoundSource {}

class _MockCalendarAccess extends Mock implements HolidayCalendarAccess {}

/// 일요일 23:48 에서 시작한다. 테스트가 [value] 를 직접 옮기거나, [follow] 로 가짜 시간을 따라가게 한다.
class _MutableClock extends Clock {
  DateTime value = DateTime(2026, 9, 27, 23, 48);
  DateTime Function()? _source;

  /// 지금부터 [start] 에서 시작해 테스트의 가짜 시간(`pump(Duration)`)만큼 흐른다.
  void follow(WidgetTester tester, DateTime start) {
    final base = tester.binding.clock.now();
    _source = () => start.add(tester.binding.clock.now().difference(base));
  }

  @override
  DateTime now() => _source?.call() ?? value;
}

const _weekdays = {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri};

/// 새 반복 알람 — 목록이 [반복] 을 고르면 여는 값.
final _newRepeat = Alarm.draft().copyWith(repeat: _weekdays);

void main() {
  late _MockUseCase useCase;
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late _MockSoundSource soundSource;
  late _MutableClock clock;
  late _MockCalendarAccess calendar;

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
    calendar = _MockCalendarAccess();
    when(calendar.ensureIfReminding).thenAnswer((_) async {});
    getIt
      ..registerSingleton<HolidayCalendarAccess>(calendar)
      ..registerSingleton<AlarmSoundSource>(soundSource)
      ..registerSingleton<AlarmUseCase>(useCase)
      ..registerSingleton<AlarmPermissions>(
        AlarmPermissions(
          notification: notification,
          exactAlarm: exactAlarm,
          fullScreenIntent: _MockRequester(),
        ),
      )
      ..registerSingleton<Clock>(clock = _MutableClock());
  });
  tearDown(getIt.reset);

  /// 편집 화면을 띄우고, 닫힐 때의 결과를 [results] 에 모은다.
  Future<List<Duration?>> pump(
    WidgetTester tester,
    Alarm initial, {
    Locale locale = const Locale('ko'),
    Size size = const Size(800, 1600),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <Duration?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(
                context,
              ).push<Duration>(MaterialPageRoute(builder: (_) => AlarmEditPage(initial: initial))),
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

  void answerSaveWithId() => when(
    () => useCase.save(any()),
  ).thenAnswer((i) async => (i.positionalArguments.single as Alarm).copyWith(id: 1));

  Alarm savedAlarm() => verify(() => useCase.save(captureAny())).captured.single as Alarm;

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, '저장')).onPressed != null;

  group('한 번 알람', () {
    testWidgets('새 한 번 알람은 0분 뒤 · 지금 시각 칩 · 저장 잠김 + 안내, 휠 · 요일은 없다', (tester) async {
      await pump(tester, Alarm.draft());

      expect(find.text('한 번 알람'), findsOneWidget);
      expect(find.text('0분 뒤'), findsOneWidget);
      expect(find.text('오후 11:48에 울림'), findsOneWidget);
      expect(find.text('시간을 더해 주세요'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      expect(find.byType(CupertinoDatePicker), findsNothing);
      expect(find.text('월'), findsNothing);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('버튼을 누르면 남은 시간 · 울릴 시각이 바뀌고, 저장하면 그 시각으로 닫힌다', (tester) async {
      answerSaveWithId();
      final results = await pump(tester, Alarm.draft());

      for (final label in ['+1시간', '+10분', '+5분', '+1분']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect(find.text('1시간 16분 뒤'), findsOneWidget);
      expect(find.text('내일 (월) 오전 1:04에 울림'), findsOneWidget);
      expect(find.text('시간을 더해 주세요'), findsNothing);
      expect(saveEnabled(tester), isTrue);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = savedAlarm();
      expect(saved.oneShotAt, DateTime(2026, 9, 28, 1, 4));
      expect((saved.hour, saved.minute), (1, 4));
      expect(saved.repeat, isEmpty);
      expect(results, [const Duration(hours: 1, minutes: 16)]);
    });

    testWidgets('초기화는 0분 뒤로 돌리고 저장을 다시 잠근다', (tester) async {
      await pump(tester, Alarm.draft());

      await tester.tap(find.text('+10분'));
      await tester.pump();
      expect(find.text('10분 뒤'), findsOneWidget);
      await tester.tap(find.text('초기화'));
      await tester.pump();

      expect(find.text('0분 뒤'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('시각 칩 → 휠 시트에서 고르면 그 시각으로 고정되고, 버튼은 그 시각에 더한다', (tester) async {
      await pump(tester, Alarm.draft());

      await tester.tap(find.text('오후 11:48에 울림'));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(DateTime(2000, 1, 1, 7, 30));
      await tester.tap(find.text('이 시각으로'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoDatePicker), findsNothing);
      expect(find.text('7시간 42분 뒤'), findsOneWidget);
      expect(find.text('내일 (월) 오전 7:30에 울림'), findsOneWidget);

      await tester.tap(find.text('+10분'));
      await tester.pump();
      expect(find.text('내일 (월) 오전 7:40에 울림'), findsOneWidget);
    });

    testWidgets('휠 시트를 그냥 닫으면 그대로', (tester) async {
      await pump(tester, Alarm.draft());

      await tester.tap(find.text('오후 11:48에 울림'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('0분 뒤'), findsOneWidget);
    });

    testWidgets('상대 모드는 1분이 지나면 N 뒤는 그대로, 울릴 시각만 다음 분 0초에 바뀐다', (tester) async {
      await pump(tester, Alarm.draft());
      await tester.tap(find.text('+1시간'));
      await tester.pump();
      expect(find.text('내일 (월) 오전 12:48에 울림'), findsOneWidget);

      clock.value = DateTime(2026, 9, 27, 23, 49);
      await tester.pump(const Duration(minutes: 1));

      expect(find.text('1시간 뒤'), findsOneWidget);
      expect(find.text('내일 (월) 오전 12:49에 울림'), findsOneWidget);
    });

    testWidgets('기존 한 번 알람(미래)은 그 시각으로 열리고 수정 제목 · 삭제가 있다', (tester) async {
      answerSaveWithId();
      await pump(
        tester,
        Alarm(id: 3, hour: 7, minute: 0, label: '낮잠', oneShotAt: DateTime(2026, 9, 28, 7)),
      );

      expect(find.text('알람 수정'), findsOneWidget);
      expect(find.text('7시간 12분 뒤'), findsOneWidget);
      expect(find.text('내일 (월) 오전 7:00에 울림'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      expect(find.widgetWithText(TextField, '낮잠'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '산책');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = savedAlarm();
      expect(saved.oneShotAt, DateTime(2026, 9, 28, 7));
      expect((saved.id, saved.hour, saved.minute, saved.label), (3, 7, 0, '산책'));
    });

    testWidgets('시각 칩으로 고정하면 그 시각으로 저장한다', (tester) async {
      answerSaveWithId();
      final results = await pump(tester, Alarm.draft());

      await tester.tap(find.text('오후 11:48에 울림'));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(DateTime(2000, 1, 1, 7, 30));
      await tester.tap(find.text('이 시각으로'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = savedAlarm();
      expect(saved.oneShotAt, DateTime(2026, 9, 28, 7, 30));
      expect((saved.hour, saved.minute), (7, 30));
      expect(results, [const Duration(hours: 7, minutes: 42)]);
    });

    testWidgets('화면을 연 초와 상관없이 다음 분 0초에 맞춰 갱신하고, 그 뒤 매분 갱신한다', (tester) async {
      clock.follow(tester, DateTime(2026, 9, 27, 23, 48, 30));
      await pump(tester, Alarm.draft());
      await tester.tap(find.text('+1시간'));
      await tester.pump();
      expect(find.text('내일 (월) 오전 12:48에 울림'), findsOneWidget);

      // 23:48:59 대 — 아직 같은 분
      await tester.pump(DateTime(2026, 9, 27, 23, 48, 59).difference(clock.now()));
      expect(find.text('내일 (월) 오전 12:48에 울림'), findsOneWidget);

      // 23:49:00 — 다음 분 0초에 바로 바뀐다
      await tester.pump(DateTime(2026, 9, 27, 23, 49).difference(clock.now()));
      expect(find.text('내일 (월) 오전 12:49에 울림'), findsOneWidget);

      await tester.pump(const Duration(minutes: 1));
      expect(find.text('내일 (월) 오전 12:50에 울림'), findsOneWidget);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('내일 (월) 오전 12:51에 울림'), findsOneWidget);
      expect(find.text('1시간 뒤'), findsOneWidget);
    });

    testWidgets('상대 모드는 분 중간에 저장해도 칩에 보인 분(초 0)에 울린다', (tester) async {
      answerSaveWithId();
      clock.value = DateTime(2026, 9, 27, 23, 40, 40);
      await pump(tester, Alarm.draft());
      await tester.tap(find.text('+10분'));
      await tester.pump();
      expect(find.text('오후 11:50에 울림'), findsOneWidget);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(savedAlarm().oneShotAt, DateTime(2026, 9, 27, 23, 50));
    });

    testWidgets('울릴 날이 오늘이 아니면 칩에 날짜를 붙인다(오늘이면 시각만)', (tester) async {
      await pump(tester, Alarm.draft());
      expect(find.text('오후 11:48에 울림'), findsOneWidget);

      await tester.tap(find.text('+10분'));
      await tester.pump();
      expect(find.text('오후 11:58에 울림'), findsOneWidget);

      await tester.tap(find.text('+10분'));
      await tester.pump();
      expect(find.text('내일 (월) 오전 12:08에 울림'), findsOneWidget);
    });

    testWidgets('고정 모드: 분이 지나면 N분 뒤가 줄고, 1분 밑으로 내려가는 순간 저장이 잠기고 안내', (tester) async {
      clock.follow(tester, DateTime(2026, 9, 27, 23, 48));
      await pump(tester, Alarm.draft());
      await tester.tap(find.text('오후 11:48에 울림'));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(DateTime(2000, 1, 1, 23, 50));
      await tester.tap(find.text('이 시각으로'));
      await tester.pumpAndSettle();
      expect(find.text('2분 뒤'), findsOneWidget);
      expect(saveEnabled(tester), isTrue);

      // 23:49:00 — 정확히 1분 남았다(아직 저장할 수 있다)
      await tester.pump(DateTime(2026, 9, 27, 23, 49).difference(clock.now()));
      expect(find.text('1분 뒤'), findsOneWidget);
      expect(saveEnabled(tester), isTrue);

      // 바로 뒤 — 1분 미만
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('0분 뒤'), findsOneWidget);
      expect(find.text('시간을 더해 주세요'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('기준 시각이 늦어 버튼이 켜져 있어도 실제로 1분 미만이면 저장하지 않고 잠금 · 안내로 돌린다', (tester) async {
      answerSaveWithId();
      await pump(
        tester,
        Alarm(id: 3, hour: 23, minute: 49, oneShotAt: DateTime(2026, 9, 27, 23, 49, 30)),
      );
      expect(saveEnabled(tester), isTrue);

      // 화면의 타이머가 돌기 전에 실제 시각이 지나갔다(남은 시간 45초).
      clock.value = DateTime(2026, 9, 27, 23, 48, 45);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      verifyNever(() => useCase.save(any()));
      expect(find.text('알람을 저장하지 못했어요'), findsNothing);
      expect(find.byType(AlarmEditPage), findsOneWidget);
      expect(find.text('시간을 더해 주세요'), findsOneWidget);
      expect(find.text('0분 뒤'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });

    testWidgets('시각 칩으로 고정하면 기준 시각을 새로 읽어 저장 가능 여부를 판단한다', (tester) async {
      await pump(tester, Alarm.draft());

      // 분 중간(23:48:20)에 23:49 를 고른다 — 남은 시간 40초.
      clock.value = DateTime(2026, 9, 27, 23, 48, 20);
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(DateTime(2000, 1, 1, 23, 49));
      await tester.tap(find.text('이 시각으로'));
      await tester.pumpAndSettle();

      expect(find.text('0분 뒤'), findsOneWidget);
      expect(find.text('시간을 더해 주세요'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
    });
  });

  group('반복 알람', () {
    testWidgets('새 반복 알람: 제목 · 휠 · 빠른 버튼(평일 선택) · 요일 원 · 요약', (tester) async {
      await pump(tester, _newRepeat);

      expect(find.text('반복 알람'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.text('0분 뒤'), findsNothing);
      ChoiceChip chip(String label) =>
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
      expect(chip('매일').selected, isFalse);
      expect(chip('평일').selected, isTrue);
      expect(chip('주말').selected, isFalse);
      for (final day in ['월', '화', '수', '목', '금', '토', '일']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(saveEnabled(tester), isTrue);
    });

    testWidgets('빠른 버튼 ↔ 요일 토글이 서로 맞는다', (tester) async {
      await pump(tester, _newRepeat);
      ChoiceChip chip(String label) =>
          tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

      await tester.tap(find.text('토').first);
      await tester.pump();
      expect([chip('매일'), chip('평일'), chip('주말')].map((c) => c.selected), [false, false, false]);

      await tester.tap(find.text('일').first);
      await tester.pump();
      expect(chip('매일').selected, isTrue);

      await tester.tap(find.widgetWithText(ChoiceChip, '주말'));
      await tester.pump();
      expect(chip('주말').selected, isTrue);
      expect(chip('매일').selected, isFalse);
      bool daySelected(String label) => tester
          .widget<Semantics>(
            find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label),
          )
          .properties
          .selected!;
      expect(daySelected('월'), isFalse);
      expect(daySelected('토'), isTrue);
    });

    testWidgets('요일을 모두 끄면 저장이 잠기고 안내', (tester) async {
      await pump(tester, Alarm.draft().copyWith(repeat: {Weekday.mon}));
      final titleTop = tester.getTopLeft(find.byType(TextField)).dy;

      await tester.tap(find.text('월').first);
      await tester.pump();

      // 요약 줄 자리는 남는다 — 아래가 위로 뛰지 않는다.
      expect(tester.getTopLeft(find.byType(TextField)).dy, titleTop);
      expect(find.text('요일을 골라 주세요'), findsOneWidget);
      expect(saveEnabled(tester), isFalse);
      // 한 번 알람 화면으로 바뀌지 않는다.
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
    });

    testWidgets('휠 · 요일 · 제목을 고르고 저장하면 use case → 권한 → 남은 시간으로 닫힌다', (tester) async {
      answerSaveWithId();
      final results = await pump(tester, Alarm.draft().copyWith(repeat: {Weekday.tue}));

      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .onDateTimeChanged(DateTime(2000, 1, 1, 6, 45));
      await tester.tap(find.text('월').first);
      await tester.tap(find.text('화').first);
      await tester.enterText(find.byType(TextField), '출근');
      await tester.pump();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = savedAlarm();
      expect(saved.repeat, {Weekday.mon});
      expect(saved.label, '출근');
      expect((saved.hour, saved.minute), (6, 45));
      verifyInOrder([notification.ensure, exactAlarm.ensure, calendar.ensureIfReminding]);
      // 일요일 23:48 → 월요일 06:45
      expect(results, [const Duration(hours: 6, minutes: 57)]);
      expect(find.byType(AlarmEditPage), findsNothing);
    });

    testWidgets('기존 알람 저장은 id · 제목 · 반복을 유지한다', (tester) async {
      const existing = Alarm(id: 3, hour: 6, minute: 30, label: '출근', repeat: {Weekday.mon});
      when(
        () => useCase.save(any()),
      ).thenAnswer((i) async => i.positionalArguments.single as Alarm);
      await pump(tester, existing);

      expect(find.text('알람 수정'), findsOneWidget);
      expect(find.widgetWithText(TextField, '출근'), findsOneWidget);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      final saved = savedAlarm();
      expect(saved.id, 3);
      expect(saved.label, '출근');
      expect(saved.repeat, {Weekday.mon});
      expect((saved.hour, saved.minute), (6, 30));
    });
  });

  testWidgets('공통 아래쪽: 제목 · 알람음 · 체크 줄 · 저장 순서, 진동 토글은 없다', (tester) async {
    await pump(
      tester,
      const Alarm(
        id: 3,
        hour: 6,
        minute: 30,
        repeat: {Weekday.mon},
        sound: AlarmSound.bundled(BundledAlarmSounds.chime),
      ),
    );

    expect(find.text('제목'), findsOneWidget);
    expect(find.text('예: 출근'), findsOneWidget);
    expect(find.text('알람음'), findsOneWidget);
    expect(find.text('차임'), findsOneWidget);
    expect(find.text('무음 · 진동 모드에선 진동만'), findsOneWidget);
    expect(find.text('폰이 무음이나 진동 모드면 소리 없이 진동으로 울려요'), findsOneWidget);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('제목'), lessThan(top('알람음')));
    expect(top('알람음'), lessThan(top('무음 · 진동 모드에선 진동만')));
    expect(top('무음 · 진동 모드에선 진동만'), lessThan(top('저장')));
    expect(find.text('진동'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('울림 설정은 체크 줄 아래 · 저장 위에 접혀 있고, 요약은 알람 값', (tester) async {
    await pump(tester, _newRepeat.copyWith(id: 3, snoozeMinutes: 10, autoStopMinutes: 5));

    expect(find.text('울림 설정'), findsOneWidget);
    expect(find.text('볼륨 80% · 스누즈 10분 · 자동 멈춤 5분'), findsOneWidget);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('무음 · 진동 모드에선 진동만'), lessThan(top('울림 설정')));
    expect(top('울림 설정'), lessThan(top('저장')));
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('울림 설정을 펼쳐 고른 값으로 저장한다', (tester) async {
    answerSaveWithId();
    await pump(tester, _newRepeat);

    await tester.tap(find.text('울림 설정'));
    await tester.pumpAndSettle();
    Finder segment(String group, String label) =>
        find.descendant(of: find.byKey(Key('ring-$group')), matching: find.text(label));
    await tester.tap(segment('fade', '30초'));
    await tester.tap(segment('snooze-interval', '15분'));
    await tester.tap(segment('snooze-limit', '3회'));
    await tester.tap(segment('auto-stop', '10분'));
    await tester.tap(find.text('30분 전에 알려 주기'));
    await tester.pump();
    expect(find.text('볼륨 80% · 스누즈 15분 · 자동 멈춤 10분'), findsOneWidget);

    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = savedAlarm();
    expect(
      (saved.fadeSeconds, saved.snoozeMinutes, saved.snoozeLimit, saved.autoStopMinutes),
      (30, 15, 3, 10),
    );
    expect(saved.remindBefore, isTrue);
  });

  testWidgets('한 번 알람도 울림 설정이 있고, 저장 때 캘린더 권한은 묻지 않는다', (tester) async {
    answerSaveWithId();
    await pump(tester, Alarm.draft());

    expect(find.text('울림 설정'), findsOneWidget);
    await tester.tap(find.text('+1시간'));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    verifyNever(calendar.ensureIfReminding);
  });

  testWidgets('체크 줄을 누르면 체크되고 그 값으로 저장한다', (tester) async {
    answerSaveWithId();
    await pump(tester, _newRepeat);

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('무음 · 진동 모드에선 진동만'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(savedAlarm().silentWhenRingerMuted, isTrue);
  });

  testWidgets('저장이 실패하면 머물고 오류 스낵바', (tester) async {
    when(() => useCase.save(any())).thenThrow(StateError('full'));
    await pump(tester, _newRepeat);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(AlarmEditPage), findsOneWidget);
    expect(find.text('알람을 저장하지 못했어요'), findsOneWidget);
  });

  testWidgets('권한 확인이 실패해도 편집 화면은 닫히고, 다시 저장해 알람이 둘이 되지 않는다', (tester) async {
    answerSaveWithId();
    when(notification.ensure).thenThrow(StateError('plugin'));
    final results = await pump(tester, Alarm.draft().copyWith(repeat: {Weekday.mon}));

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
    await pump(tester, _newRepeat);

    await tester.tap(find.text('저장'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    saving.complete(const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon}));
    await tester.pumpAndSettle();

    verify(() => useCase.save(any())).called(1);
    expect(find.byType(AlarmEditPage), findsNothing);
  });

  testWidgets('새 알람의 알람음은 시스템 기본', (tester) async {
    await pump(tester, Alarm.draft());

    expect(find.text('시스템 기본'), findsOneWidget);
  });

  testWidgets('알람음 줄 → 선택 화면에서 고르면 줄에 반영되고 그 소리로 저장한다', (tester) async {
    when(() => useCase.save(any())).thenAnswer((i) async => i.positionalArguments.single as Alarm);
    await pump(tester, const Alarm(id: 3, hour: 6, minute: 30, repeat: {Weekday.mon}));

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

    expect(savedAlarm().sound, const AlarmSound.bundled(BundledAlarmSounds.beep));
  });

  testWidgets('선택 화면에서 그냥 돌아오면 알람음은 그대로', (tester) async {
    await pump(tester, const Alarm(id: 3, hour: 6, minute: 30, repeat: {Weekday.mon}));

    await tester.tap(find.text('알람음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('비프'));
    await tester.pump();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(find.text('시스템 기본'), findsOneWidget);
    expect(find.text('비프'), findsNothing);
  });

  testWidgets('제목을 입력하다 알람음 줄을 누르면 포커스를 풀고, 돌아와도 다시 잡지 않는다', (tester) async {
    await pump(tester, const Alarm(id: 3, hour: 6, minute: 30, repeat: {Weekday.mon}));
    final titleFocus = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    bool titleFocused() => titleFocus.hasFocus;

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(titleFocused(), isTrue);

    await tester.tap(find.text('알람음'));
    await tester.pumpAndSettle();
    expect(titleFocused(), isFalse);
    expect(tester.testTextInput.isVisible, isFalse);

    for (final back in [
      () => tester.state<NavigatorState>(find.byType(Navigator)).maybePop(),
      () async {
        await tester.tap(find.text('비프'));
        await tester.pump();
        await tester.tap(find.text('선택'));
      },
    ]) {
      if (find.byType(AlarmSoundPage).evaluate().isEmpty) {
        await tester.tap(find.text('알람음'));
        await tester.pumpAndSettle();
      }
      await back();
      await tester.pumpAndSettle();

      expect(find.byType(AlarmSoundPage), findsNothing);
      expect(titleFocused(), isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    }
  });

  testWidgets('편집: 삭제는 확인 뒤 지우고 결과 없이 닫힌다', (tester) async {
    when(() => useCase.delete(3)).thenAnswer((_) async {});
    final results = await pump(
      tester,
      const Alarm(id: 3, hour: 6, minute: 30, repeat: {Weekday.mon}),
    );

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('알람을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();

    verify(() => useCase.delete(3)).called(1);
    expect(results, [null]);
  });

  group('복제', () {
    const saved = Alarm(id: 3, hour: 6, minute: 30, label: '출근', repeat: {Weekday.mon});

    Future<void> openDuplicate(WidgetTester tester) async {
      await tester.tap(find.byTooltip('더보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('복제'));
      await tester.pumpAndSettle();
    }

    testWidgets('새 알람에는 앱바 메뉴가 없다', (tester) async {
      await pump(tester, _newRepeat);

      expect(find.byTooltip('더보기'), findsNothing);
    });

    testWidgets('편집 앱바 메뉴 [복제] 는 같은 설정의 새 알람 편집을 위에 연다', (tester) async {
      await pump(tester, saved.copyWith(skippedAt: DateTime(2026, 9, 28, 6, 30)));

      await openDuplicate(tester);

      expect(find.byType(AlarmEditPage), findsOneWidget); // 원래 화면은 아래에 남는다
      expect(find.byType(AlarmEditPage, skipOffstage: false), findsNWidgets(2));
      expect(find.text('반복 알람'), findsOneWidget);
      expect(find.widgetWithText(TextField, '출근'), findsOneWidget);
    });

    testWidgets('복제본을 저장하면 새 알람으로 저장하고 두 화면이 남은 시간으로 닫힌다', (tester) async {
      answerSaveWithId();
      final results = await pump(tester, saved);

      await openDuplicate(tester);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(savedAlarm(), saved.copyWith(id: Alarm.unsavedId));
      expect(find.byType(AlarmEditPage, skipOffstage: false), findsNothing);
      // 일요일 23:48 → 월요일 06:30.
      expect(results, [const Duration(hours: 6, minutes: 42)]);
    });

    testWidgets('복제본을 그냥 닫으면 원래 편집 화면으로 돌아온다', (tester) async {
      final results = await pump(tester, saved);

      await openDuplicate(tester);
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();

      expect(find.byType(AlarmEditPage), findsOneWidget);
      expect(find.text('알람 수정'), findsOneWidget);
      expect(results, isEmpty);
      verifyNever(() => useCase.save(any()));
    });
  });

  testWidgets('좁은 화면(320dp)에서도 요일 토글 7개가 한 줄에 오버플로 없이 들어간다', (tester) async {
    await pump(tester, _newRepeat, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
    final positions = Weekday.values
        .map((day) => tester.getTopLeft(find.text(AlarmFormat.weekday('ko', day))).dy)
        .toSet();
    expect(positions, hasLength(1), reason: '요일 토글은 모두 같은 줄(같은 dy)에 있어야 한다');
  });

  for (final locale in const [Locale('ko'), Locale('en'), Locale('ja')]) {
    testWidgets('320dp 에서 넘치지 않는다 — 한 번 · 시각 시트 ($locale)', (tester) async {
      await pump(
        tester,
        Alarm(id: 3, hour: 7, minute: 0, label: '낮잠', oneShotAt: DateTime(2026, 9, 28, 7)),
        locale: locale,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('320dp 에서 넘치지 않는다 — 반복 · 안내 ($locale)', (tester) async {
      await pump(
        tester,
        Alarm.draft().copyWith(repeat: {Weekday.mon}),
        locale: locale,
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(AlarmFormat.weekday(locale.languageCode, Weekday.mon)).first);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
