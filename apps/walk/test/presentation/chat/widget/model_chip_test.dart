import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
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
        body: Center(
          child: ModelChip(data: data, onPressed: onPressed),
        ),
      ),
    ),
  );

  const data = ModelChipData(
    vendor: ChatVendor.anthropic,
    label: 'Claude Sonnet 9.5',
  );

  testWidgets('이름 · 모노그램 · ▾ 가 보인다', (tester) async {
    var taps = 0;
    await pump(tester, data, onPressed: () => taps++);

    expect(find.byKey(const Key('chat-model-chip')), findsOneWidget);
    expect(find.text('Claude Sonnet 9.5'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsNothing);
    expect(find.bySemanticsLabel('새 모델이 있어요'), findsNothing);
    expect(find.byTooltip('모델 바꾸기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-model-chip')));
    expect(taps, 1);
  });

  testWidgets('fastMode 면 번개 아이콘', (tester) async {
    await pump(
      tester,
      const ModelChipData(
        vendor: ChatVendor.anthropic,
        label: 'Claude Sonnet 9.5',
        fastMode: true,
      ),
      onPressed: () {},
    );

    expect(find.byIcon(Icons.bolt), findsOneWidget);
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

    expect(find.byKey(const Key('chat-model-chip-dot')), findsOneWidget);
    expect(find.bySemanticsLabel('새 모델이 있어요'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('onPressed null 이면 눌러도 아무 일 없음', (tester) async {
    await pump(tester, data);

    await tester.tap(
      find.byKey(const Key('chat-model-chip')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final chip = tester.widget<ActionChip>(
      find.descendant(
        of: find.byKey(const Key('chat-model-chip')),
        matching: find.byType(ActionChip),
        matchRoot: true,
      ),
    );
    expect(chip.onPressed, isNull);
  });
}
