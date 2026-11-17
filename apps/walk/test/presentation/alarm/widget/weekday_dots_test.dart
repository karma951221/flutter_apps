import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/widget/weekday_dots.dart';

void main() {
  Future<ColorScheme> pump(WidgetTester tester, Widget dots) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: dots),
      ),
    );
    return Theme.of(tester.element(find.byType(WeekdayDots))).colorScheme;
  }

  Color? colorOf(WidgetTester tester, Weekday day) =>
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(ValueKey('weekday-dot-${day.name}')),
                  )
                  .decoration
              as BoxDecoration)
          .color;

  testWidgets('월~일 7개, 켜진 요일은 primary · 나머지는 outlineVariant', (tester) async {
    final scheme = await pump(
      tester,
      const WeekdayDots(days: {Weekday.mon, Weekday.fri}),
    );

    for (final day in Weekday.values) {
      final on = day == Weekday.mon || day == Weekday.fri;
      expect(
        colorOf(tester, day),
        on ? scheme.primary : scheme.outlineVariant,
        reason: day.name,
      );
    }
    final xs = [
      for (final day in Weekday.values)
        tester.getTopLeft(find.byKey(ValueKey('weekday-dot-${day.name}'))).dx,
    ];
    expect(xs, [...xs]..sort(), reason: '월요일부터 왼쪽에서 오른쪽으로');
  });

  testWidgets('흐리게면 켜진 요일도 onSurfaceVariant', (tester) async {
    final scheme = await pump(
      tester,
      const WeekdayDots(days: {Weekday.mon}, dimmed: true),
    );

    expect(colorOf(tester, Weekday.mon), scheme.onSurfaceVariant);
    expect(colorOf(tester, Weekday.tue), scheme.outlineVariant);
  });
}
