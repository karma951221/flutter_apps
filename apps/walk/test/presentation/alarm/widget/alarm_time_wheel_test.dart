import 'package:design_system/design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/alarm/widget/alarm_time_wheel.dart';

void main() {
  late List<TimeOfDay> changes;

  setUp(() => changes = []);

  Future<void> pump(
    WidgetTester tester,
    TimeOfDay initial, {
    Locale locale = const Locale('ko'),
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AlarmTimeWheel(initial: initial, onChanged: changes.add),
      ),
    ),
  );

  String? hourLabel(WidgetTester tester, String hour) =>
      tester.widget<Text>(find.text(hour).first).semanticsLabel;

  // QA: 분이 43 인데 시 열이 "12시 정각"으로 읽혔다(Cupertino 기본 시 라벨은 "N시 정각").
  for (final (locale, label, oClock) in [
    (const Locale('ko'), '12시', '정각'),
    (const Locale('en'), '12 hours', "o'clock"),
    (const Locale('ja'), '12時', 'ちょうど'),
  ]) {
    testWidgets('시 열 라벨은 분과 어긋나는 "정각"이 아니다 ($locale)', (tester) async {
      await pump(tester, const TimeOfDay(hour: 0, minute: 43), locale: locale);

      expect(hourLabel(tester, '12'), label);
      expect(find.bySemanticsLabel(RegExp(oClock)), findsNothing);
    });
  }

  testWidgets('휠 전체는 지금 고른 시각을 라벨로 읽히고, 바꾸면 따라간다', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const TimeOfDay(hour: 0, minute: 43));

    expect(find.bySemanticsLabel('오전 12:43'), findsOneWidget);

    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(DateTime(2000, 1, 1, 7, 5));
    await tester.pump();

    expect(changes, [const TimeOfDay(hour: 7, minute: 5)]);
    expect(find.bySemanticsLabel('오전 7:05'), findsOneWidget);
    expect(find.bySemanticsLabel('오전 12:43'), findsNothing);
    handle.dispose();
  });

  testWidgets('maximum 을 주면 그 뒤 시각은 휠에서 고를 수 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AlarmTimeWheel(
            initial: const TimeOfDay(hour: 9, minute: 0),
            maximum: const TimeOfDay(hour: 9, minute: 30),
            onChanged: changes.add,
          ),
        ),
      ),
    );

    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.maximumDate, DateTime(2000, 1, 1, 9, 30));
  });
}
