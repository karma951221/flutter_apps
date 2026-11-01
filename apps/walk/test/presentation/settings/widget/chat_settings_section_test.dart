import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/presentation/settings/widget/chat_settings_section.dart';

import '../../../support/fake_chat_settings.dart';

void main() {
  late FakeChatSettings settings;

  setUp(() {
    settings = FakeChatSettings();
    getIt.registerSingleton<ChatSettings>(settings);
  });
  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: ChatSettingsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('키가 없으면 키 넣기 행을 보이고, 입력해 저장하면 마스킹 미리보기가 보인다', (tester) async {
    await pump(tester);

    expect(find.text('키 넣기'), findsOneWidget);
    expect(find.textContaining('Anthropic 으로 전송돼요'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-chat-key')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sk-ant-api03-xyz1234');
    await tester.tap(find.byKey(const Key('chat-key-save')));
    await tester.pumpAndSettle();

    expect(find.text('sk-ant-api03-xyz1••••'), findsOneWidget);
    expect(find.text('키 넣기'), findsNothing);
    expect(settings.key, 'sk-ant-api03-xyz1234');
  });

  testWidgets('키가 있으면 삭제를 확인한 뒤 지운다', (tester) async {
    settings.key = 'sk-ant-api03-xyz1234';
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-chat-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('키 삭제').last);
    await tester.pumpAndSettle();

    expect(settings.key, isNull);
    expect(find.text('키 넣기'), findsOneWidget);
  });

  testWidgets('키를 저장하지 못하면 스낵바로 알린다', (tester) async {
    await pump(tester);
    settings.failWith = Exception('keystore');

    await tester.tap(find.byKey(const Key('settings-chat-key')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sk-ant-api03-xyz1234');
    await tester.tap(find.byKey(const Key('chat-key-save')));
    await tester.pump();
    await tester.pump();

    expect(find.text('키를 저장하지 못했어요'), findsOneWidget);
    expect(find.text('키 넣기'), findsOneWidget);
  });

  testWidgets('키를 지우지 못해도 스낵바로 알린다', (tester) async {
    settings.key = 'sk-ant-api03-xyz1234';
    await pump(tester);
    settings.failWith = Exception('keystore');

    await tester.tap(find.byKey(const Key('settings-chat-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('키 삭제').last);
    await tester.pump();
    await tester.pump();

    expect(find.text('키를 저장하지 못했어요'), findsOneWidget);
    expect(find.text('sk-ant-api03-xyz1••••'), findsOneWidget);
  });
}
