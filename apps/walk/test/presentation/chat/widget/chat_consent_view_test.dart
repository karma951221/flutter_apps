import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/chat/widget/chat_consent_view.dart';

void main() {
  var accepted = 0;

  setUp(() => accepted = 0);

  Future<void> pump(
    WidgetTester tester, {
    required ChatVendor vendor,
    bool continuing = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatConsentView(
          vendor: vendor,
          continuing: continuing,
          onAccept: () => accepted++,
        ),
      ),
    ),
  );

  testWidgets('문구에 벤더 이름', (tester) async {
    await pump(tester, vendor: ChatVendor.openai);

    expect(find.textContaining('연결한 AI(GPT)로 전송돼요'), findsOneWidget);
    expect(find.textContaining('지금 대화의 이전 내용도'), findsNothing);

    await tester.tap(find.text('동의하고 시작'));
    expect(accepted, 1);
  });

  testWidgets("continuing 이면 '지금 대화의 이전 내용도 GPT 로 보내져요'", (tester) async {
    await pump(tester, vendor: ChatVendor.openai, continuing: true);

    expect(find.textContaining('연결한 AI(GPT)로 전송돼요'), findsOneWidget);
    expect(find.text('지금 대화의 이전 내용도 GPT 로 보내져요.'), findsOneWidget);
  });
}
