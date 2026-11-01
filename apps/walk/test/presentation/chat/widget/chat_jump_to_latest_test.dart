import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/chat/widget/chat_jump_to_latest.dart';

void main() {
  Widget app(VoidCallback onPressed) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(child: ChatJumpToLatest(onPressed: onPressed)),
    ),
  );

  testWidgets("라벨 '새 답'과 아래 화살표, 누르면 onPressed", (tester) async {
    var pressed = 0;
    await tester.pumpWidget(app(() => pressed++));

    expect(find.text('↓ 새 답'), findsOneWidget);
    await tester.tap(find.byType(ChatJumpToLatest));
    expect(pressed, 1);
  });

  testWidgets('AppButton 을 쓴다', (tester) async {
    await tester.pumpWidget(app(() {}));

    expect(
      find.descendant(
        of: find.byType(ChatJumpToLatest),
        matching: find.byType(AppButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('화면 너비로 퍼지지 않는다', (tester) async {
    await tester.pumpWidget(app(() {}));

    expect(
      tester.getSize(find.byType(ChatJumpToLatest)).width,
      lessThan(tester.getSize(find.byType(Scaffold)).width / 2),
    );
  });
}
