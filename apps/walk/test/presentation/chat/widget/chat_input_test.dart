import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'package:walk/presentation/chat/widget/attachment_chip.dart';
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

  testWidgets('enabled 가 false 면 입력칸과 전송 버튼이 꺼진다', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(
      host(
        ChatInput(busy: false, enabled: false, onSend: sent.add, onStop: () {}),
      ),
    );

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    final send = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send),
    );
    expect(send.onPressed, isNull);
  });

  group('첨부', () {
    const pending = [
      ChatAttachmentRef(name: 'a.pdf', kind: AttachmentKind.pdf),
      ChatAttachmentRef(name: 'b.jpg', kind: AttachmentKind.image),
    ];

    testWidgets('첨부 2개면 칩 2개, ✕ 를 누르면 그 index 로 onRemoveAttachment', (
      tester,
    ) async {
      final removed = <int>[];
      await tester.pumpWidget(
        host(
          ChatInput(
            busy: false,
            onSend: (_) {},
            onStop: () {},
            attachments: pending,
            onRemoveAttachment: removed.add,
          ),
        ),
      );

      expect(find.byType(AttachmentChip), findsNWidgets(2));
      expect(find.text('a.pdf'), findsOneWidget);
      expect(find.text('b.jpg'), findsOneWidget);
      await tester.tap(find.byTooltip('첨부 빼기').first);

      expect(removed, [0]);
    });

    testWidgets('글이 비어도 첨부가 있으면 보낸다', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        host(
          ChatInput(
            busy: false,
            onSend: sent.add,
            onStop: () {},
            attachments: pending,
            onRemoveAttachment: (_) {},
          ),
        ),
      );

      await tester.tap(find.byTooltip('보내기'));

      expect(sent, ['']);
    });

    testWidgets('글도 첨부도 없으면 보내지 않는다', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        host(ChatInput(busy: false, onSend: sent.add, onStop: () {})),
      );

      await tester.tap(find.byTooltip('보내기'));

      expect(sent, isEmpty);
    });

    testWidgets('📎 를 누르면 onAttach', (tester) async {
      var attached = 0;
      await tester.pumpWidget(
        host(
          ChatInput(
            busy: false,
            onSend: (_) {},
            onStop: () {},
            onAttach: () => attached++,
          ),
        ),
      );

      await tester.tap(find.byTooltip('파일 첨부'));

      expect(attached, 1);
    });

    testWidgets('canAttach 가 false 면 📎 가 꺼지고 툴팁이 이유', (tester) async {
      var attached = 0;
      await tester.pumpWidget(
        host(
          ChatInput(
            busy: false,
            onSend: (_) {},
            onStop: () {},
            onAttach: () => attached++,
            canAttach: false,
            attachBlockedReason: '한 번에 3개까지 첨부할 수 있어요',
          ),
        ),
      );

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.attach_file),
      );
      expect(button.onPressed, isNull);
      expect(button.tooltip, '한 번에 3개까지 첨부할 수 있어요');
      expect(attached, 0);
    });
  });
}
