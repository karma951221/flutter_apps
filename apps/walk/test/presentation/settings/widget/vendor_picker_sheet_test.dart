import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/settings/widget/vendor_picker_sheet.dart';

void main() {
  /// 시트가 닫히며 돌려준 값. 아직 안 닫혔으면 [open] 그대로.
  late Object? result;
  const open = #open;

  setUp(() => result = open);

  Future<void> show(WidgetTester tester, {ChatVendor? current}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await VendorPickerSheet.show(
                  context,
                  current: current,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder row(ChatVendor vendor) => find.byKey(Key('vendor-row-${vendor.name}'));

  testWidgets('Claude · GPT 두 행만, Grok 없음', (tester) async {
    await show(tester);

    expect(find.text('AI 고르기'), findsOneWidget);
    expect(chatVendorChoices, [ChatVendor.anthropic, ChatVendor.openai]);
    expect(find.byType(AppListTile), findsNWidgets(2));
    expect(
      find.descendant(
        of: row(ChatVendor.anthropic),
        matching: find.text('Claude'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row(ChatVendor.anthropic),
        matching: find.text('Anthropic'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row(ChatVendor.openai), matching: find.text('GPT')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row(ChatVendor.openai),
        matching: find.text('OpenAI'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Grok'), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('지금 벤더는 체크이고 누를 수 없다', (tester) async {
    await show(tester, current: ChatVendor.anthropic);

    expect(
      find.descendant(
        of: row(ChatVendor.anthropic),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(tester.widget<AppListTile>(row(ChatVendor.anthropic)).onTap, isNull);

    await tester.tap(row(ChatVendor.anthropic), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('AI 고르기'), findsOneWidget);
    expect(result, open);
  });

  testWidgets('고르면 그 벤더로 닫힌다', (tester) async {
    await show(tester, current: ChatVendor.anthropic);

    await tester.tap(row(ChatVendor.openai));
    await tester.pumpAndSettle();

    expect(find.text('AI 고르기'), findsNothing);
    expect(result, ChatVendor.openai);
  });

  testWidgets('바깥을 눌러 닫으면 null', (tester) async {
    await show(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
