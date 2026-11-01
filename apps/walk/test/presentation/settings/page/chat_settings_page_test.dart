import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/usecase/chat_key_verifier.dart';
import 'package:walk/presentation/settings/page/chat_settings_page.dart';
import 'package:walk/presentation/settings/widget/chat_settings_section.dart';

import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_settings.dart';

void main() {
  setUp(() {
    getIt
      ..registerSingleton<ChatSettings>(FakeChatSettings())
      ..registerSingleton<ChatKeyVerifier>(FakeChatKeyVerifier());
  });
  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('highlightConnection 을 섹션에 넘긴다', (tester) async {
    await pump(tester, const ChatSettingsPage(highlightConnection: true));

    expect(find.text('물어보기 설정'), findsOneWidget);
    expect(
      tester
          .widget<ChatSettingsSection>(find.byType(ChatSettingsSection))
          .highlightConnection,
      isTrue,
    );
  });

  testWidgets('기본은 강조하지 않는다', (tester) async {
    await pump(tester, const ChatSettingsPage());

    expect(
      tester
          .widget<ChatSettingsSection>(find.byType(ChatSettingsSection))
          .highlightConnection,
      isFalse,
    );
  });
}
