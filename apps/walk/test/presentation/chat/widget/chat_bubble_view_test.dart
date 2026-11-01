import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/presentation/chat/cubit/chat_state.dart';
import 'package:walk/presentation/chat/widget/chat_bubble_view.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    ChatBubble bubble, {
    VoidCallback? onOpenSettings,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatBubbleView(
          bubble: bubble,
          onOpenCited: (_, _) {},
          onOpenSettings: onOpenSettings,
        ),
      ),
    ),
  );

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
}
