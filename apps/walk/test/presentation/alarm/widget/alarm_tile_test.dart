import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/widget/alarm_tile.dart';
import 'package:walk/presentation/alarm/widget/weekday_dots.dart';

const _weekdays = {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.fri};

Widget _app(
  Alarm alarm, {
  ValueChanged<bool>? onToggle,
  VoidCallback? onTap,
  Duration? untilRing,
  Locale locale = const Locale('ko'),
}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: AlarmTile(
      alarm: alarm,
      untilRing: untilRing,
      onTap: onTap ?? () {},
      onToggle: onToggle ?? (_) {},
    ),
  ),
);

void main() {
  ColorScheme schemeOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(AlarmTile))).colorScheme;

  testWidgets('둥근 카드 행(surfaceContainerLow · AppRadius.lg)', (tester) async {
    await tester.pumpWidget(_app(const Alarm(id: 1, hour: 7, minute: 0, repeat: _weekdays)));

    final card = tester.widget<Material>(
      find.descendant(of: find.byType(AlarmTile), matching: find.byType(Material)).first,
    );
    expect(card.color, schemeOf(tester).surfaceContainerLow);
    expect(card.borderRadius, AppRadius.lgAll);
  });

  testWidgets('반복 알람: 큰 시각(오전/오후는 작게) · 제목 · 반복 요약 · 요일 점, 남은 시간 줄은 없다', (tester) async {
    await tester.pumpWidget(
      _app(
        const Alarm(id: 1, hour: 7, minute: 0, label: '출근', repeat: _weekdays),
        untilRing: const Duration(hours: 7, minutes: 12),
      ),
    );

    expect(find.text('오전 7:00'), findsOneWidget);
    final time = tester.widget<Text>(find.text('오전 7:00'));
    final spans = (time.textSpan! as TextSpan).children!.cast<TextSpan>();
    final period = spans.singleWhere((s) => s.text == '오전');
    final digits = spans.singleWhere((s) => s.text!.contains('7:00'));
    expect(digits.style, isNull, reason: '숫자는 Text 의 큰 글자 그대로');
    expect(period.style!.fontSize, lessThan(time.style!.fontSize!));

    expect(find.text('출근 · 평일'), findsOneWidget);
    expect(tester.widget<WeekdayDots>(find.byType(WeekdayDots)).days, _weekdays);
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
    expect(find.textContaining('후'), findsNothing);
  });

  testWidgets('제목이 없으면 반복 요약만', (tester) async {
    await tester.pumpWidget(_app(const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon})));

    expect(find.text('월'), findsOneWidget);
  });

  testWidgets('한 번 알람: 모래시계 + 한 번 · N 뒤, 요일 점은 없다', (tester) async {
    await tester.pumpWidget(
      _app(
        Alarm(id: 1, hour: 16, minute: 50, label: '낮잠', oneShotAt: DateTime(2026, 9, 28, 16, 50)),
        untilRing: const Duration(hours: 1, minutes: 25),
      ),
    );

    expect(find.text('오후 4:50'), findsOneWidget);
    expect(find.text('낮잠'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.text('한 번 · 1시간 25분 뒤'), findsOneWidget);
    expect(find.byType(WeekdayDots), findsNothing);
  });

  testWidgets('꺼진 한 번 알람은 모래시계 + 한 번만', (tester) async {
    await tester.pumpWidget(
      _app(
        const Alarm(id: 1, hour: 7, minute: 0, enabled: false),
        untilRing: const Duration(hours: 1),
      ),
    );

    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.text('한 번'), findsOneWidget);
    expect(find.textContaining('뒤'), findsNothing);
  });

  testWidgets('꺼진 알람의 시각 · 요약 · 요일 점은 흐리게, 켜진 알람은 그대로', (tester) async {
    await tester.pumpWidget(
      _app(const Alarm(id: 1, hour: 7, minute: 0, enabled: false, repeat: {Weekday.mon})),
    );
    final scheme = schemeOf(tester);
    expect(tester.widget<Text>(find.text('오전 7:00')).style?.color, scheme.onSurfaceVariant);
    expect(tester.widget<Text>(find.text('월')).style?.color, scheme.onSurfaceVariant);
    expect(tester.widget<WeekdayDots>(find.byType(WeekdayDots)).dimmed, isTrue);

    await tester.pumpWidget(_app(const Alarm(id: 1, hour: 7, minute: 0, repeat: {Weekday.mon})));
    expect(tester.widget<Text>(find.text('오전 7:00')).style?.color, isNot(scheme.onSurfaceVariant));
    expect(tester.widget<Text>(find.text('월')).style?.color, isNot(scheme.onSurfaceVariant));
    expect(tester.widget<WeekdayDots>(find.byType(WeekdayDots)).dimmed, isFalse);
  });

  testWidgets('꺼져도 행 탭은 동작한다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(const Alarm(id: 1, hour: 7, minute: 0, enabled: false), onTap: () => taps++),
    );
    await tester.tap(find.text('오전 7:00'));
    expect(taps, 1);
  });

  testWidgets('스위치를 누르면 햅틱 후 onToggle', (tester) async {
    final haptics = <String?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments as String?);
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    bool? toggled;
    await tester.pumpWidget(
      _app(const Alarm(id: 1, hour: 7, minute: 0), onToggle: (v) => toggled = v),
    );

    await tester.tap(find.byType(Switch));

    expect(toggled, isFalse);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  for (final locale in const [Locale('ko'), Locale('en'), Locale('ja')]) {
    testWidgets('320dp 에서 긴 제목도 넘치지 않는다 ($locale)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const label = '아주아주 긴 제목이 들어가는 알람 아주아주 긴 제목';
      await tester.pumpWidget(
        _app(
          const Alarm(
            id: 1,
            hour: 23,
            minute: 59,
            label: label,
            repeat: {Weekday.mon, Weekday.wed},
          ),
          locale: locale,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _app(
          Alarm(
            id: 1,
            hour: 23,
            minute: 59,
            label: label,
            oneShotAt: DateTime(2026, 9, 28, 23, 59),
          ),
          untilRing: const Duration(hours: 23, minutes: 59),
          locale: locale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
