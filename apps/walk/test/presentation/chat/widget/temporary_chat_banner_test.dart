import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/chat/widget/temporary_chat_banner.dart';

void main() {
  testWidgets('벤더 이름이 든 안내를 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: TemporaryChatBanner(vendor: ChatVendor.anthropic),
        ),
      ),
    );

    expect(find.byKey(const Key('chat-temporary-banner')), findsOneWidget);
    expect(
      find.text(
        '임시 대화 · 이 폰에 저장되지 않아요. 질문과 찾은 기록은 Anthropic에 전송되고, '
        '그곳의 보관 정책은 앱이 정할 수 없어요.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
