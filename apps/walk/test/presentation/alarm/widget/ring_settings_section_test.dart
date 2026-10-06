import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/widget/ring_settings_section.dart';

const _alarm = Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon});

void main() {
  late List<Object?> calls;

  setUp(() => calls = []);

  Future<void> pump(
    WidgetTester tester,
    Alarm alarm, {
    Locale locale = const Locale('ko'),
    Size size = const Size(800, 1600),
    bool enabled = true,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              RingSettingsSection(
                alarm: alarm,
                enabled: enabled,
                onVolumePercent: (v) => calls.add(('volume', v)),
                onFadeSeconds: (v) => calls.add(('fade', v)),
                onSnoozeMinutes: (v) => calls.add(('snooze', v)),
                onSnoozeLimit: (v) => calls.add(('limit', v)),
                onAutoStopMinutes: (v) => calls.add(('autoStop', v)),
                onRemindBefore: (v) => calls.add(('remind', v)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> expand(WidgetTester tester) async {
    await tester.tap(find.text('울림 설정'));
    await tester.pumpAndSettle();
  }

  Finder segment(String group, String label) =>
      find.descendant(of: find.byKey(Key('ring-$group')), matching: find.text(label));

  testWidgets('접힌 상태는 제목 · 한 줄 요약만', (tester) async {
    await pump(tester, _alarm);

    expect(find.text('울림 설정'), findsOneWidget);
    expect(find.text('볼륨 80% · 스누즈 5분 · 자동 멈춤 없음'), findsOneWidget);
    expect(find.byType(Slider), findsNothing);
    expect(find.text('30분 전에 알려 주기'), findsNothing);
  });

  testWidgets('요약은 알람 값을 따른다', (tester) async {
    await pump(
      tester,
      _alarm.copyWith(volumePercent: 50, snoozeMinutes: 15, autoStopMinutes: 10),
    );

    expect(find.text('볼륨 50% · 스누즈 15분 · 자동 멈춤 10분'), findsOneWidget);
  });

  testWidgets('펼치면 볼륨 · 점점 커지기 · 스누즈 간격 · 횟수 · 자동 멈춤 · 30분 전 알림', (tester) async {
    await pump(tester, _alarm);
    await expand(tester);

    expect(find.text('볼륨'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect((slider.min, slider.max, slider.divisions, slider.value), (10.0, 100.0, 9, 80.0));
    expect(find.text('점점 커지기'), findsOneWidget);
    for (final label in ['끔', '30초', '60초']) {
      expect(segment('fade', label), findsOneWidget);
    }
    expect(find.text('스누즈 간격'), findsOneWidget);
    for (final label in ['5분', '10분', '15분']) {
      expect(segment('snooze-interval', label), findsOneWidget);
    }
    expect(find.text('스누즈 횟수'), findsOneWidget);
    for (final label in ['무제한', '3회']) {
      expect(segment('snooze-limit', label), findsOneWidget);
    }
    expect(find.text('자동 멈춤'), findsOneWidget);
    for (final label in ['안 함', '5분', '10분', '15분']) {
      expect(segment('auto-stop', label), findsOneWidget);
    }
    expect(find.text('30분 전에 알려 주기'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    SegmentedButton<int> button(String group) =>
        tester.widget<SegmentedButton<int>>(
          find.descendant(
            of: find.byKey(Key('ring-$group')),
            matching: find.byType(SegmentedButton<int>),
          ),
        );
    // 선택지 순서의 index 로 고른다: 끔 · 5분 · 무제한 · 안 함.
    expect(button('fade').selected, {0});
    expect(button('snooze-interval').selected, {0});
    expect(button('snooze-limit').selected, {0});
    expect(button('auto-stop').selected, {0});
  });

  testWidgets('고르면 그 값으로 알린다(무제한 · 안 함은 null)', (tester) async {
    await pump(
      tester,
      _alarm.copyWith(snoozeLimit: 3, autoStopMinutes: 5, fadeSeconds: 30),
    );
    await expand(tester);

    await tester.tap(segment('fade', '60초'));
    await tester.tap(segment('snooze-interval', '10분'));
    await tester.tap(segment('snooze-limit', '무제한'));
    await tester.tap(segment('auto-stop', '안 함'));
    await tester.tap(segment('auto-stop', '15분'));
    await tester.tap(find.text('30분 전에 알려 주기'));
    await tester.pump();

    expect(calls, [
      ('fade', 60),
      ('snooze', 10),
      ('limit', null),
      ('autoStop', null),
      ('autoStop', 15),
      ('remind', true),
    ]);
  });

  testWidgets('볼륨 슬라이더를 끌면 10 단위 값으로 알린다', (tester) async {
    await pump(tester, _alarm);
    await expand(tester);

    await tester.drag(find.byType(Slider), const Offset(-2000, 0));
    await tester.pump();

    expect(calls.last, ('volume', 10));
  });

  testWidgets('저장 중(enabled false)이면 고를 수 없다', (tester) async {
    await pump(tester, _alarm, enabled: false);
    await expand(tester);

    await tester.tap(segment('snooze-interval', '10분'));
    await tester.tap(find.text('30분 전에 알려 주기'));
    await tester.pump();

    expect(calls, isEmpty);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  for (final locale in const [Locale('ko'), Locale('en'), Locale('ja')]) {
    testWidgets('320dp 에서 펼쳐도 넘치지 않는다 ($locale)', (tester) async {
      await pump(
        tester,
        _alarm.copyWith(autoStopMinutes: 15),
        locale: locale,
        size: const Size(320, 1200),
      );
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
