import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/lock/widget/pin_pad.dart';

void main() {
  late List<String> completed;

  setUp(() => completed = []);

  Future<void> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool error = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PinPad(
          onCompleted: completed.add,
          enabled: enabled,
          error: error,
        ),
      ),
    ),
  );

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.widgetWithText(TextButton, d));
      await tester.pump();
    }
  }

  testWidgets('점 4개를 그리고 누른 만큼 채운다', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(4));
    expect(find.byIcon(Icons.circle), findsNothing);

    await tapDigits(tester, '12');

    expect(find.byIcon(Icons.circle), findsNWidgets(2));
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
  });

  testWidgets('4번째 숫자에서 onCompleted 를 부르고 비운다', (tester) async {
    await pump(tester);

    await tapDigits(tester, '123');
    expect(completed, isEmpty);
    await tapDigits(tester, '4');

    expect(completed, ['1234']);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('지우기는 마지막 숫자를 뺀다', (tester) async {
    await pump(tester);

    await tapDigits(tester, '12');
    await tester.tap(find.text('지우기'));
    await tester.pump();
    await tapDigits(tester, '345');

    expect(completed, ['1345']);
  });

  testWidgets('enabled false 면 탭을 무시한다', (tester) async {
    await pump(tester, enabled: false);

    await tapDigits(tester, '1234');

    expect(completed, isEmpty);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('error 면 점을 오류 색으로 그린다', (tester) async {
    await pump(tester, error: true);
    final scheme = Theme.of(tester.element(find.byType(PinPad))).colorScheme;

    final dot = tester.widget<Icon>(find.byIcon(Icons.circle_outlined).first);

    expect(dot.color, scheme.error);
  });
}
