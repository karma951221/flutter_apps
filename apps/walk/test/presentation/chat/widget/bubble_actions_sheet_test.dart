import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/chat/widget/bubble_actions_sheet.dart';

Future<BubbleAction?> _open(
  WidgetTester tester, {
  bool canSaveToFile = false,
}) async {
  BubbleAction? result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showBubbleActions(
            context,
            canSaveToFile: canSaveToFile,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('글 있는 답 말풍선에는 [파일로 저장]이 보이고 누르면 saveToFile', (tester) async {
    BubbleAction? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                picked = await showBubbleActions(context, canSaveToFile: true),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('파일로 저장'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-bubble-action-save')));
    await tester.pumpAndSettle();
    expect(picked, BubbleAction.saveToFile);
  });

  testWidgets('글 없는 말풍선에는 [파일로 저장]이 없다', (tester) async {
    await _open(tester);

    expect(find.byKey(const Key('chat-bubble-action-save')), findsNothing);
    expect(find.text('파일로 저장'), findsNothing);
  });
}
