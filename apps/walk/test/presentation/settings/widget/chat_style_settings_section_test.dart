import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/settings/widget/chat_style_settings_section.dart';

import '../../../support/fake_chat_style_settings.dart';

void main() {
  Future<void> pump(WidgetTester tester, FakeChatStyleSettings style) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(children: [ChatStyleSettingsSection(style: style)]),
          ),
        ),
      );

  testWidgets("'답' 묶음 — 말투 행과 그림 만들기 스위치(처음엔 켬)", (tester) async {
    await pump(tester, FakeChatStyleSettings());

    expect(find.text('답'), findsOneWidget);
    expect(find.byKey(const Key('chat-tone-tile')), findsOneWidget);
    expect(find.text('그림 만들기'), findsOneWidget);
    final toggle = tester.widget<Switch>(
      find.byKey(const Key('chat-settings-image-generation')),
    );
    expect(toggle.value, isTrue);
  });

  testWidgets('행을 누르면 그림 만들기를 끄고 저장한다', (tester) async {
    final style = FakeChatStyleSettings();
    await pump(tester, style);

    await tester.tap(find.text('그림 만들기'));
    await tester.pumpAndSettle();

    expect(style.imageGeneration, isFalse);
    final toggle = tester.widget<Switch>(
      find.byKey(const Key('chat-settings-image-generation')),
    );
    expect(toggle.value, isFalse);
  });
}
