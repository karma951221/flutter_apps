import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/chat/widget/bubble_actions_sheet.dart';

/// 시트를 연다. 고른 항목은 [onPicked] 로 — 시트가 닫힌 뒤에야 온다.
Future<void> _showSheet(
  WidgetTester tester, {
  required bool canSaveToFile,
  ValueChanged<BubbleAction?>? onPicked,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onPicked?.call(
            await showBubbleActions(context, canSaveToFile: canSaveToFile),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('글 있는 답 말풍선에는 [파일로 저장]이 보이고 누르면 saveToFile', (tester) async {
    BubbleAction? picked;
    await _showSheet(
      tester,
      canSaveToFile: true,
      onPicked: (action) => picked = action,
    );

    expect(find.text('파일로 저장'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-bubble-action-save')));
    await tester.pumpAndSettle();
    expect(picked, BubbleAction.saveToFile);
  });

  testWidgets('글 없는 말풍선에는 [파일로 저장]이 없다', (tester) async {
    await _showSheet(tester, canSaveToFile: false);

    expect(find.byKey(const Key('chat-bubble-action-save')), findsNothing);
    expect(find.text('파일로 저장'), findsNothing);
  });
}
