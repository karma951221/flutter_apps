import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/chat/widget/chat_settings_action.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool hasNewer = false,
    VoidCallback? onPressed,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          actions: [
            ChatSettingsAction(
              hasNewer: hasNewer,
              onPressed: onPressed ?? () {},
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets("설정 아이콘 버튼(툴팁 '대화 설정'), 누르면 onPressed", (tester) async {
    var taps = 0;
    await pump(tester, onPressed: () => taps++);

    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byTooltip('대화 설정'), findsOneWidget);
    expect(find.byKey(const Key('chat-settings-action-dot')), findsNothing);

    await tester.tap(find.byKey(const Key('chat-settings-action')));
    expect(taps, 1);
  });

  testWidgets("hasNewer 면 점(시맨틱 '새 모델이 있어요')", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, hasNewer: true);

    expect(find.byKey(const Key('chat-settings-action-dot')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('새 모델이 있어요')), findsOneWidget);
    handle.dispose();
  });
}
