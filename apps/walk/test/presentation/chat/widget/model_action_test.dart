import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/chat/widget/model_action.dart';
import 'package:walk/presentation/chat/widget/model_chip.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    ModelChipData data, {
    VoidCallback? onPressed,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          actions: [ModelAction(data: data, onPressed: onPressed)],
        ),
      ),
    ),
  );

  const data = ModelChipData(
    vendor: ChatVendor.anthropic,
    label: 'Claude Sonnet 9.5',
  );

  IconButton button(WidgetTester tester) => tester.widget<IconButton>(
    find.descendant(
      of: find.byKey(const Key('chat-model-action')),
      matching: find.byType(IconButton),
      matchRoot: true,
    ),
  );

  testWidgets('벤더 모노그램 아이콘 버튼, 툴팁에 지금 모델', (tester) async {
    var taps = 0;
    await pump(tester, data, onPressed: () => taps++);

    expect(find.text('C'), findsOneWidget);
    expect(find.byTooltip('모델 바꾸기 · 지금 Claude Sonnet 9.5'), findsOneWidget);
    expect(find.byKey(const Key('chat-model-action-dot')), findsNothing);

    await tester.tap(find.byKey(const Key('chat-model-action')));
    expect(taps, 1);
  });

  testWidgets("hasNewer 면 점(시맨틱 '새 모델이 있어요')", (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const ModelChipData(
        vendor: ChatVendor.openai,
        label: 'GPT 9',
        hasNewer: true,
      ),
      onPressed: () {},
    );

    expect(find.byKey(const Key('chat-model-action-dot')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('새 모델이 있어요')), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('onPressed null 이면 비활성', (tester) async {
    await pump(tester, data);

    expect(button(tester).onPressed, isNull);
  });
}
