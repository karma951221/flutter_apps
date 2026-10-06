import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = AppTheme.light();

  Future<void> pump(
    WidgetTester tester, {
    required int count,
    bool isActive = false,
    bool animate = false,
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: AppCountAction(
              icon: Icons.favorite,
              count: count,
              tooltip: '좋아요',
              onPressed: () {},
              isActive: isActive,
              animate: animate,
            ),
          ),
        ),
      ),
    ),
  );

  Finder inAction(Type type) => find.descendant(
    of: find.byType(AppCountAction),
    matching: find.byType(type),
  );

  Color? iconColor(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(Icons.favorite)).color;

  testWidgets('개수를 그리고 누르면 콜백을 부른다', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCountAction(
            icon: Icons.favorite,
            count: 3,
            tooltip: '좋아요',
            onPressed: () => tapped++,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(AppCountAction));
    expect(tapped, 1);
  });

  testWidgets('기본값이면 전환 위젯 없이 바로 바뀐다', (tester) async {
    await pump(tester, count: 1);
    await pump(tester, count: 2, isActive: true);

    expect(inAction(AnimatedSwitcher), findsNothing);
    expect(inAction(ScaleTransition), findsNothing);
    expect(inAction(TweenAnimationBuilder<Color?>), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(iconColor(tester), theme.colorScheme.primary);
  });

  testWidgets('animate 면 숫자를 미끄러뜨리고 끝나면 새 값만 남는다', (tester) async {
    await pump(tester, count: 1, animate: true);
    await pump(tester, count: 2, isActive: true, animate: true);

    expect(inAction(AnimatedSwitcher), findsOneWidget);
    expect(inAction(SlideTransition), findsWidgets);
    // 전환 중에는 나가는 숫자와 들어오는 숫자가 함께 있다.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(iconColor(tester), theme.colorScheme.primary);
  });

  testWidgets('animate 면 늘 때는 아래에서, 줄 때는 위에서 들어온다', (tester) async {
    Offset incomingStart(String text) => tester
        .widget<SlideTransition>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(SlideTransition),
              )
              .first,
        )
        .position
        .value;

    await pump(tester, count: 1, animate: true);
    await pump(tester, count: 2, animate: true);
    expect(incomingStart('2').dy, greaterThan(0));
    await tester.pumpAndSettle();

    await pump(tester, count: 1, animate: true);
    expect(incomingStart('1').dy, lessThan(0));
    await tester.pumpAndSettle();
  });

  testWidgets('animate 면 켜질 때 아이콘이 튀었다가 원래 크기로 돌아온다', (tester) async {
    await pump(tester, count: 1, animate: true);
    await pump(tester, count: 1, isActive: true, animate: true);
    await tester.pump(AppMotion.medium ~/ 2);

    final scale = tester
        .widget<ScaleTransition>(
          find.ancestor(
            of: find.byIcon(Icons.favorite),
            matching: find.byType(ScaleTransition),
          ),
        )
        .scale;
    expect(scale.value, greaterThan(1));

    await tester.pumpAndSettle();
    expect(scale.value, 1);
  });

  testWidgets('애니메이션 줄이기면 animate 여도 전환 없이 최종 상태', (tester) async {
    await pump(tester, count: 1, animate: true, disableAnimations: true);
    await pump(
      tester,
      count: 2,
      isActive: true,
      animate: true,
      disableAnimations: true,
    );

    expect(inAction(AnimatedSwitcher), findsNothing);
    expect(inAction(ScaleTransition), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(iconColor(tester), theme.colorScheme.primary);
  });
}
