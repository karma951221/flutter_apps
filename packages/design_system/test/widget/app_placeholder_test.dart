import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('메시지만 있으면 메시지만 그린다', (tester) async {
    await pump(tester, const AppPlaceholder(message: '불러오지 못했습니다'));

    expect(find.text('불러오지 못했습니다'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('아이콘은 넘겼을 때만 그린다', (tester) async {
    await pump(
      tester,
      const AppPlaceholder(message: '비어 있습니다', icon: Icons.edit_note_outlined),
    );

    expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
  });

  testWidgets('보조 설명은 넘겼을 때만 그린다', (tester) async {
    await pump(
      tester,
      const AppPlaceholder(message: '비어 있습니다', description: '첫 글을 남겨보세요.'),
    );

    expect(find.text('첫 글을 남겨보세요.'), findsOneWidget);
  });

  testWidgets('행동 버튼은 라벨과 콜백이 둘 다 있어야 그린다', (tester) async {
    await pump(
      tester,
      const AppPlaceholder(message: '실패', actionLabel: '다시 시도'),
    );
    expect(find.text('다시 시도'), findsNothing);

    var tapped = 0;
    await pump(
      tester,
      AppPlaceholder(
        message: '실패',
        actionLabel: '다시 시도',
        onAction: () => tapped++,
      ),
    );
    await tester.tap(find.text('다시 시도'));
    expect(tapped, 1);
  });

  testWidgets('actionKey 가 버튼에 전달된다', (tester) async {
    await pump(
      tester,
      AppPlaceholder(
        message: '실패',
        actionLabel: '다시 시도',
        onAction: () {},
        actionKey: const Key('retry'),
      ),
    );

    expect(find.byKey(const Key('retry')), findsOneWidget);
  });

  group('animateIn', () {
    Future<void> pumpAnimated(
      WidgetTester tester, {
      required bool animateIn,
      bool disableAnimations = false,
      String message = '비어 있습니다',
    }) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Center(
              child: AppPlaceholder(message: message, animateIn: animateIn),
            ),
          ),
        ),
      ),
    );

    Finder inPlaceholder(Type type) => find.descendant(
      of: find.byType(AppPlaceholder),
      matching: find.byType(type),
    );

    testWidgets('기본값이면 전환 위젯 없이 그린다', (tester) async {
      await pumpAnimated(tester, animateIn: false);

      expect(inPlaceholder(TweenAnimationBuilder<double>), findsNothing);
      expect(inPlaceholder(Opacity), findsNothing);
      expect(find.text('비어 있습니다'), findsOneWidget);
    });

    testWidgets('켜면 투명에서 시작해 끝나면 완전히 보인다', (tester) async {
      await pumpAnimated(tester, animateIn: true);

      expect(inPlaceholder(TweenAnimationBuilder<double>), findsOneWidget);
      expect(tester.widget<Opacity>(inPlaceholder(Opacity)).opacity, 0);

      await tester.pumpAndSettle();

      expect(tester.widget<Opacity>(inPlaceholder(Opacity)).opacity, 1);
      expect(find.text('비어 있습니다'), findsOneWidget);
    });

    testWidgets('다시 빌드돼도 재생하지 않는다', (tester) async {
      await pumpAnimated(tester, animateIn: true);
      await tester.pumpAndSettle();

      await pumpAnimated(tester, animateIn: true, message: '불러오지 못했습니다');

      expect(tester.widget<Opacity>(inPlaceholder(Opacity)).opacity, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('애니메이션 줄이기면 켜도 바로 최종 상태', (tester) async {
      await pumpAnimated(tester, animateIn: true, disableAnimations: true);

      expect(inPlaceholder(TweenAnimationBuilder<double>), findsNothing);
      expect(inPlaceholder(Opacity), findsNothing);
      expect(find.text('비어 있습니다'), findsOneWidget);
    });
  });
}
