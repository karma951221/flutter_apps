import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';
import 'package:walk/presentation/chat/widget/attachment_chip.dart';
import 'package:walk/presentation/chat/widget/chat_bubble_view.dart';

/// 1×1 투명 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

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
    Future<Uint8List?> Function(String path)? readImage,
    bool pending = false,
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
          readImage: readImage,
          pending: pending,
        ),
      ),
    ),
  );

  group('답 말풍선 마크다운', () {
    final cursor = find.textContaining('▍', findRichText: true);

    testWidgets('답은 마크다운으로 — 굵게 기호 없이 그리고 SelectionArea 로 고른다', (tester) async {
      await pump(
        tester,
        const ChatBubble(role: ChatRole.assistant, text: '**굵게** 와 `코드`'),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(find.textContaining('**', findRichText: true), findsNothing);
      expect(find.textContaining('굵게', findRichText: true), findsOneWidget);
    });

    testWidgets('질문은 마크다운으로 그리지 않는다(평문 SelectableText)', (tester) async {
      await pump(tester, const ChatBubble(role: ChatRole.user, text: '**별**'));

      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.text('**별**'), findsOneWidget);
    });

    testWidgets('streaming 이면 글 끝에 커서, 아니면 없다', (tester) async {
      const answer = ChatBubble(role: ChatRole.assistant, text: '지난주에는');
      await pump(tester, answer, streaming: true);
      expect(cursor, findsOneWidget);

      await pump(tester, answer);
      expect(cursor, findsNothing);
    });

    testWidgets('streaming 이어도 글이 없으면(자리 표시) 커서 없음', (tester) async {
      await pump(
        tester,
        const ChatBubble(role: ChatRole.assistant, text: ''),
        pending: true,
        streaming: true,
      );
      expect(find.text('…'), findsOneWidget);
      expect(cursor, findsNothing);
    });

    testWidgets('닫힌 svg 블록은 그림으로 그린다', (tester) async {
      await pump(
        tester,
        const ChatBubble(
          role: ChatRole.assistant,
          text:
              '도식:\n```svg\n<svg viewBox="0 0 10 10"><rect width="10" height="10"/></svg>\n```',
        ),
      );
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('작업 폴더 그림은 readImage 로 읽어 보이고 누르면 그 경로를 연다', (tester) async {
      final opened = <String>[];
      final read = <String>[];
      await pump(
        tester,
        const ChatBubble(
          role: ChatRole.assistant,
          text: '다 됐어요.\n\n![노을](out/%EA%B7%B8%EB%A6%BC-1.png)',
        ),
        readImage: (path) async {
          read.add(path);
          return _png;
        },
        onOpenAttachment: opened.add,
      );
      await tester.pumpAndSettle();

      expect(read, ['out/그림-1.png']);
      expect(find.byType(Image), findsOneWidget);
      // 테스트에선 그림이 풀리지 않아 크기가 0 — 누르기 대신 탭 콜백을 부른다.
      final tap = tester.widget<GestureDetector>(
        find.ancestor(
          of: find.byType(Image),
          matching: find.byType(GestureDetector),
        ).first,
      );
      tap.onTap!();
      expect(opened, ['out/그림-1.png']);
    });

    testWidgets('없는 그림은 "그림을 찾을 수 없어요"', (tester) async {
      await pump(
        tester,
        const ChatBubble(
          role: ChatRole.assistant,
          text: '![노을](out/gone.png)',
        ),
        readImage: (_) async => null,
      );
      await tester.pumpAndSettle();

      expect(find.text('그림을 찾을 수 없어요'), findsOneWidget);
    });

    testWidgets('작업 폴더 밖(웹 주소) 그림은 불러오지 않고 설명 글만', (tester) async {
      final read = <String>[];
      await pump(
        tester,
        const ChatBubble(
          role: ChatRole.assistant,
          text: '![고양이](https://example.com/cat.png)',
        ),
        readImage: (path) async {
          read.add(path);
          return null;
        },
      );
      await tester.pumpAndSettle();

      expect(read, isEmpty);
      expect(find.textContaining('고양이', findRichText: true), findsOneWidget);
    });

    testWidgets('답 글을 길게 누르면 고르기 메뉴 끝의 [더보기]가 onLongPress 를 부른다', (
      tester,
    ) async {
      var pressed = 0;
      await pump(
        tester,
        const ChatBubble(role: ChatRole.assistant, text: '지난주에는 걸었어요'),
        onLongPress: () => pressed++,
      );

      await tester.longPress(
        find.textContaining('지난주에는', findRichText: true).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('더보기'));
      await tester.pumpAndSettle();

      expect(pressed, 1);
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

    testWidgets('없는 파일은 회색 "지운 파일" — 눌러도 열지 않는다', (tester) async {
      final opened = <String>[];
      await pump(
        tester,
        bubble,
        attachmentExists: (path) async => path == 'inbox/a.pdf',
        onOpenAttachment: opened.add,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('지운 파일'), findsOneWidget);
      expect(find.text('gone.md · 지운 파일'), findsOneWidget);
      final gone = tester.widget<InputChip>(
        find.ancestor(
          of: find.textContaining('gone.md'),
          matching: find.byType(InputChip),
        ),
      );
      expect(gone.isEnabled, isFalse);

      await tester.tap(find.textContaining('gone.md'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });

    testWidgets('경로가 없는 첨부(임시 대화)는 표시만 — 흐리지 않은 Chip · "지운 파일" 없음 · 누르기 없음', (
      tester,
    ) async {
      final asked = <String>[];
      final opened = <String>[];
      await pump(
        tester,
        bubble,
        attachmentExists: (path) async {
          asked.add(path);
          return true;
        },
        onOpenAttachment: opened.add,
      );
      await tester.pumpAndSettle();

      expect(find.text('temp.jpg'), findsOneWidget);
      // 비활성 InputChip 이 아니라 보통 Chip — 지운 파일처럼 흐려 보이지 않는다.
      expect(
        find.ancestor(
          of: find.text('temp.jpg'),
          matching: find.byType(InputChip),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(of: find.text('temp.jpg'), matching: find.byType(Chip)),
        findsOneWidget,
      );
      expect(asked, hasLength(2)); // a.pdf · gone.md 만 묻는다
      await tester.tap(find.text('temp.jpg'));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });

    testWidgets('있는지 묻는 동안은 흐리지 않은 Chip — 지운 파일로 번쩍이지 않는다', (tester) async {
      final answer = Completer<bool>();
      await pump(
        tester,
        bubble,
        attachmentExists: (path) => answer.future,
        onOpenAttachment: (_) {},
      );
      await tester.pump();

      expect(find.textContaining('지운 파일'), findsNothing);
      expect(find.byType(InputChip), findsNothing);
      expect(find.byType(Chip), findsNWidgets(3));

      answer.complete(true);
      await tester.pumpAndSettle();
      // 있다고 답하면 누를 수 있는 칩이 된다.
      expect(
        find.ancestor(of: find.text('a.pdf'), matching: find.byType(InputChip)),
        findsOneWidget,
      );
    });

    testWidgets('있는지 묻다 실패하면 지운 파일로 본다', (tester) async {
      await pump(
        tester,
        bubble,
        attachmentExists: (path) => throw StateError('boundary'),
        onOpenAttachment: (_) {},
      );
      await tester.pumpAndSettle();

      // 경로가 있는 둘만 — 경로 없는 temp.jpg 는 묻지 않는다.
      expect(find.textContaining('지운 파일'), findsNWidgets(2));
      expect(find.text('temp.jpg'), findsOneWidget);
    });
  });
}
