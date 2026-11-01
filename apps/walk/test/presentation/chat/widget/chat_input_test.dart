import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/chat/widget/chat_input.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('busy 가 아니면 전송 버튼, 누르면 onSend', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      host(ChatInput(busy: false, onSend: sent.add, onStop: () {})),
    );

    expect(find.byIcon(Icons.stop_rounded), findsNothing);
    await tester.enterText(find.byType(TextField), '  어제 뭐 했어? ');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();

    expect(sent, ['어제 뭐 했어?']);
    expect(find.text('어제 뭐 했어?'), findsNothing);
  });

  testWidgets("busy 면 멈춤 버튼(툴팁 '답 멈추기'), 누르면 onStop", (tester) async {
    var stopped = 0;
    await tester.pumpWidget(
      host(ChatInput(busy: true, onSend: (_) {}, onStop: () => stopped++)),
    );

    expect(find.byIcon(Icons.send), findsNothing);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('답 멈추기'));

    expect(stopped, 1);
  });

  testWidgets('busy 여도 글자 칸은 입력할 수 있다', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      host(ChatInput(busy: true, onSend: sent.add, onStop: () {})),
    );

    await tester.enterText(find.byType(TextField), '다음 질문');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(find.text('다음 질문'), findsOneWidget);
    expect(sent, isEmpty);
  });

  group('restoredDraft', () {
    Future<void> restore(
      WidgetTester tester, {
      required VoidCallback onRestored,
      String? typed,
    }) async {
      Widget input(String? draft) => host(
        ChatInput(
          busy: draft == null,
          onSend: (_) {},
          onStop: () {},
          restoredDraft: draft,
          onDraftRestored: onRestored,
        ),
      );
      await tester.pumpWidget(input(null));
      if (typed != null) await tester.enterText(find.byType(TextField), typed);
      await tester.pumpWidget(input('어제 뭐 했어?'));
      await tester.pump();
    }

    testWidgets('restoredDraft 가 오면 빈 입력칸을 채우고 커서가 끝, onDraftRestored 를 부른다', (
      tester,
    ) async {
      var restored = 0;
      await restore(tester, onRestored: () => restored++);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '어제 뭐 했어?');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: '어제 뭐 했어?'.length),
      );
      expect(restored, 1);
      // 키보드는 열지 않는다.
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('입력칸에 글이 있으면 덮어쓰지 않는다', (tester) async {
      var restored = 0;
      await restore(tester, onRestored: () => restored++, typed: '쓰던 글');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '쓰던 글');
      expect(restored, 1);
    });
  });
}
