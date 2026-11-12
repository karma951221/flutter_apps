import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';
import 'package:walk/presentation/chat/widget/attachment_chip.dart';
import 'package:walk/presentation/chat/widget/chat_bubble_view.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    ChatBubble bubble, {
    VoidCallback? onOpenSettings,
    VoidCallback? onLongPress,
    bool streaming = false,
    bool reduceMotion = false,
    Future<bool> Function(String path)? attachmentExists,
    ValueChanged<String>? onOpenAttachment,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatBubbleView(
          bubble: bubble,
          onOpenCited: (_, _) {},
          onOpenSettings: onOpenSettings,
          onLongPress: onLongPress,
          streaming: streaming,
          attachmentExists: attachmentExists,
          onOpenAttachment: onOpenAttachment,
        ),
      ),
    ),
  );

  group('흐르는 중 커서', () {
    const answer = ChatBubble(role: ChatRole.assistant, text: '지난주에는');
    final cursor = find.textContaining('▍', findRichText: true);

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(of: cursor, matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;

    testWidgets('streaming 이면 커서가 보이고 SelectableText 글에는 없다', (tester) async {
      await pump(tester, answer, streaming: true);

      expect(cursor, findsOneWidget);
      final selectable = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectable.data, '지난주에는');
      expect(selectable.data, isNot(contains('▍')));
      // 커서는 글 끝에 붙는다 — 글과 같은 줄에서 시작한다.
      expect(
        tester.getTopLeft(cursor).dy,
        tester.getTopLeft(find.byType(SelectableText)).dy,
      );
    });

    // 캐럿 자리 몇 픽셀 차이로 한 줄 글자 수가 갈리는 너비들. 글 너비 = 0.85 × 화면 − 좌우 여백 32,
    // 테스트 글꼴 한 글자 16.5.
    //  - 1010 → 826.5 = 16.5 × 50 + 1.5: 캐럿 자리가 3 보다 작으면(예: 0) 한 줄 글자 수가 늘어난다.
    //  - 1012 → 828.2 = 16.5 × 50 + 3.2: 캐럿 자리가 3 보다 크면(예: 4) 한 줄 글자 수가 줄어든다.
    const testGlyph = 16.5;
    // RenderEditable._caretMargin = _kCaretGap(1) + cursorWidth(기본 2).
    const caretMargin = 3.0;
    for (final width in [1010.0, 1012.0]) {
      testWidgets('여러 줄이어도 투명 글이 같은 자리에서 줄을 나눈다(너비 $width)', (tester) async {
        tester.view
          ..physicalSize = Size(width, 800)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (var n = 1; n <= 60; n++) {
          final text = '바다가' * n;
          await pump(
            tester,
            ChatBubble(role: ChatRole.assistant, text: text),
            streaming: true,
          );
          final whole = TextSelection(baseOffset: 0, extentOffset: text.length);
          final editable = tester
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          final paragraph = tester.renderObject<RenderParagraph>(cursor);
          final expected = editable.getBoxesForSelection(whole).last;
          final actual = paragraph
              .getBoxesForSelection(
                whole,
                boxHeightStyle: editable.selectionHeightStyle,
                boxWidthStyle: editable.selectionWidthStyle,
              )
              .last;
          // 글이 줄 끝을 꽉 채운 경우는 뺀다 — 테스트 글꼴은 폭 없는 빈칸(U+200B)에도 글자
          // 폭을 줘서 마지막 글자까지 커서와 함께 넘긴다(실제 글꼴에서는 폭 0).
          if (expected.right + testGlyph > editable.size.width - caretMargin) {
            continue;
          }
          // 투명 글의 끝(= 커서 자리)이 보이는 글의 끝과 같다 — 같은 줄(한 줄 높이 차이가 아님),
          // 같은 가로 자리. 글이 줄 끝을 꽉 채워 커서만 다음 줄로 넘기면 줄 간격 몫으로
          // 아래 끝이 몇 픽셀 달라질 수 있다.
          expect(actual.right, expected.right, reason: 'n=$n');
          expect(
            actual.bottom,
            closeTo(expected.bottom, (expected.bottom - expected.top) / 2),
            reason: 'n=$n',
          );
          expect(
            tester.getTopLeft(cursor),
            tester.getTopLeft(find.byType(SelectableText)),
          );
        }
      });
    }

    testWidgets('깜빡인다 — AppMotion.long 뒤 불투명도가 바뀐다', (tester) async {
      await pump(tester, answer, streaming: true);
      final before = opacity(tester);
      await tester.pump(AppMotion.long);
      expect(opacity(tester), isNot(before));
    });

    testWidgets('줄이기 모드면 커서가 깜빡이지 않는다', (tester) async {
      await pump(tester, answer, streaming: true, reduceMotion: true);

      expect(cursor, findsOneWidget);
      final before = opacity(tester);
      await tester.pump(AppMotion.long);
      expect(opacity(tester), before);
      expect(before, 1);
    });

    testWidgets('streaming 이 아니면 커서 없음', (tester) async {
      await pump(tester, answer);

      expect(cursor, findsNothing);
    });

    testWidgets('streaming 이어도 글이 없으면 커서 없음', (tester) async {
      await pump(
        tester,
        const ChatBubble(role: ChatRole.assistant, text: ''),
        streaming: true,
      );

      expect(cursor, findsNothing);
    });
  });

  testWidgets("stopped 면 글 아래에 '멈춤'과 정지 아이콘, 오류 색이 아니다", (tester) async {
    await pump(
      tester,
      const ChatBubble(role: ChatRole.assistant, text: '반쯤', stopped: true),
    );

    final context = tester.element(find.byType(ChatBubbleView));
    final scheme = Theme.of(context).colorScheme;
    final label = tester.widget<Text>(find.text('멈춤'));
    final icon = tester.widget<Icon>(find.byIcon(Icons.stop_circle_outlined));
    expect(label.style?.color, scheme.onSurfaceVariant);
    expect(label.style?.color, isNot(scheme.error));
    expect(icon.color, scheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.text('멈춤')).dy,
      greaterThan(tester.getBottomLeft(find.text('반쯤')).dy),
    );
  });

  testWidgets('stopped 가 아니면 없다', (tester) async {
    await pump(
      tester,
      const ChatBubble(role: ChatRole.assistant, text: '다 됐어요'),
    );

    expect(find.text('멈춤'), findsNothing);
    expect(find.byIcon(Icons.stop_circle_outlined), findsNothing);
  });

  group('실패 말풍선 [설정 열기]', () {
    const openSettings = Key('chat-bubble-open-settings');
    const keyFailures = {
      ChatFailure.noKey,
      ChatFailure.invalidKey,
      ChatFailure.quotaExceeded,
    };

    ChatBubble failed(ChatFailure failure) =>
        ChatBubble(role: ChatRole.assistant, text: '반쯤', failure: failure);

    for (final failure in keyFailures) {
      testWidgets('${failure.name} 실패면 실패 문구 아래 [설정 열기], 누르면 콜백', (
        tester,
      ) async {
        var opened = 0;
        await pump(tester, failed(failure), onOpenSettings: () => opened++);

        final button = find.byKey(openSettings);
        expect(button, findsOneWidget);
        expect(
          find.descendant(of: button, matching: find.text('설정 열기')),
          findsOneWidget,
        );
        expect(find.byType(AppButton), findsOneWidget);
        expect(
          tester.getTopLeft(button).dy,
          greaterThan(tester.getTopLeft(find.text('반쯤')).dy),
        );
        await tester.tap(button);
        expect(opened, 1);
      });
    }

    for (final failure in ChatFailure.values.where(
      (f) => !keyFailures.contains(f),
    )) {
      testWidgets('${failure.name} 실패에는 없다', (tester) async {
        await pump(tester, failed(failure), onOpenSettings: () {});

        expect(find.byKey(openSettings), findsNothing);
      });
    }

    testWidgets('콜백이 null 이면 없다', (tester) async {
      await pump(tester, failed(ChatFailure.invalidKey));

      expect(find.byKey(openSettings), findsNothing);
    });

    testWidgets('실패가 없으면 없다', (tester) async {
      await pump(
        tester,
        const ChatBubble(role: ChatRole.assistant, text: '다 됐어요'),
        onOpenSettings: () {},
      );

      expect(find.byKey(openSettings), findsNothing);
    });
  });

  testWidgets('말풍선 여백을 길게 누르면 onLongPress', (tester) async {
    var pressed = 0;
    await pump(
      tester,
      const ChatBubble(role: ChatRole.user, text: '어제 뭐 했어?'),
      onLongPress: () => pressed++,
    );

    // 글 바깥(말풍선 안쪽 여백).
    final text = tester.getRect(find.text('어제 뭐 했어?'));
    await tester.longPressAt(text.topLeft + const Offset(-4, -4));
    await tester.pumpAndSettle();

    expect(pressed, 1);
  });

  testWidgets('글을 길게 누르면 고르기 메뉴 끝의 [더보기]가 onLongPress 를 부른다', (tester) async {
    var pressed = 0;
    await pump(
      tester,
      const ChatBubble(role: ChatRole.user, text: '어제 뭐 했어?'),
      onLongPress: () => pressed++,
    );

    await tester.longPress(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();
    expect(find.text('복사'), findsOneWidget);
    await tester.tap(find.text('더보기'));
    await tester.pumpAndSettle();

    expect(pressed, 1);
    expect(find.text('더보기'), findsNothing);
  });

  testWidgets('onLongPress 가 없으면 고르기 메뉴에 [더보기]가 없다', (tester) async {
    await pump(tester, const ChatBubble(role: ChatRole.user, text: '어제 뭐 했어?'));

    await tester.longPress(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    expect(find.text('복사'), findsOneWidget);
    expect(find.text('더보기'), findsNothing);
  });

  testWidgets('질문 말풍선은 첨부를 칩(이름 · 종류 아이콘)으로 보이고 ✕ 는 없다', (tester) async {
    await pump(
      tester,
      const ChatBubble(
        role: ChatRole.user,
        text: '봐 줘',
        attachments: [
          ChatAttachmentRef(name: 'a.pdf', kind: AttachmentKind.pdf),
          ChatAttachmentRef(name: 'b.jpg', kind: AttachmentKind.image),
        ],
      ),
    );

    expect(find.byType(AttachmentChip), findsNWidgets(2));
    expect(find.text('a.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byTooltip('첨부 빼기'), findsNothing);
  });

  group('기록 말풍선 첨부 칩', () {
    const bubble = ChatBubble(
      role: ChatRole.user,
      text: '봐 줘',
      attachments: [
        ChatAttachmentRef(
          name: 'a.pdf',
          kind: AttachmentKind.pdf,
          workspacePath: 'inbox/a.pdf',
        ),
        ChatAttachmentRef(
          name: 'gone.md',
          kind: AttachmentKind.text,
          workspacePath: 'inbox/gone.md',
        ),
        ChatAttachmentRef(name: 'temp.jpg', kind: AttachmentKind.image),
      ],
    );

    testWidgets('있는 파일은 누르면 그 경로를 연다', (tester) async {
      final opened = <String>[];
      await pump(
        tester,
        bubble,
        attachmentExists: (path) async => path == 'inbox/a.pdf',
        onOpenAttachment: opened.add,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('a.pdf'));
      await tester.pumpAndSettle();

      expect(opened, ['inbox/a.pdf']);
    });

    testWidgets('없거나 경로가 없는 파일은 회색 "지운 파일" — 눌러도 열지 않는다', (tester) async {
      final opened = <String>[];
      await pump(
        tester,
        bubble,
        attachmentExists: (path) async => path == 'inbox/a.pdf',
        onOpenAttachment: opened.add,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('지운 파일'), findsNWidgets(2));
      expect(find.textContaining('a.pdf · 지운 파일'), findsNothing);
      final gone = tester.widget<InputChip>(
        find.ancestor(
          of: find.textContaining('gone.md'),
          matching: find.byType(InputChip),
        ),
      );
      expect(gone.isEnabled, isFalse);

      await tester.tap(find.textContaining('gone.md'), warnIfMissed: false);
      await tester.tap(find.textContaining('temp.jpg'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });

    testWidgets('있는지 묻다 실패하면 지운 파일로 본다', (tester) async {
      await pump(
        tester,
        bubble,
        attachmentExists: (path) => throw StateError('boundary'),
        onOpenAttachment: (_) {},
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('지운 파일'), findsNWidgets(3));
    });
  });
}
