import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/presentation/alarm/widget/alarm_summary_card.dart';

final _alarm = const Alarm(id: 1, hour: 7, minute: 0, label: '출근');

Widget _app(DateTime now) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('ko'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: AlarmSummaryCard(
      alarms: [_alarm],
      nextAt: {1: DateTime(2026, 10, 4, 7, 0)},
      now: now,
    ),
  ),
);

void main() {
  testWidgets('초록 컨테이너 색 카드, 남은 시간은 onPrimaryContainer', (tester) async {
    await tester.pumpWidget(_app(DateTime(2026, 10, 3, 22, 0)));
    final scheme = Theme.of(tester.element(find.byType(Card))).colorScheme;

    expect(
      tester.widget<Card>(find.byType(Card)).color,
      scheme.primaryContainer,
    );
    expect(
      tester.widget<Card>(find.byType(Card)).shape,
      const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
    );
    final remaining = tester.widget<Text>(
      find.byKey(const Key('alarm-summary-remaining')),
    );
    expect(remaining.style?.color, scheme.onPrimaryContainer);
  });

  testWidgets('시간이 바뀌면 AnimatedSwitcher 로 새 남은 시간으로 바뀐다', (tester) async {
    await tester.pumpWidget(_app(DateTime(2026, 10, 3, 22, 0)));
    expect(find.byType(AnimatedSwitcher), findsOneWidget);
    final before = tester
        .widget<Text>(find.byKey(const Key('alarm-summary-remaining')))
        .data;

    await tester.pumpWidget(_app(DateTime(2026, 10, 3, 22, 1)));
    await tester.pumpAndSettle();

    final after = tester
        .widget<Text>(find.byKey(const Key('alarm-summary-remaining')))
        .data;
    expect(after, isNot(before));
    expect(find.byKey(const Key('alarm-summary-remaining')), findsOneWidget);
    expect(find.byKey(const Key('alarm-summary-when')), findsOneWidget);
  });
}
