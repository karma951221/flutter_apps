import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget button, {
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: button)),
      ),
    ),
  );

  Finder inButton(Type type) =>
      find.descendant(of: find.byType(AppButton), matching: find.byType(type));

  testWidgets('변형마다 해당 Material 버튼을 그린다', (tester) async {
    await pump(tester, AppButton.primary(label: '저장', onPressed: () {}));
    expect(find.byType(FilledButton), findsOneWidget);

    await pump(tester, AppButton.secondary(label: '취소', onPressed: () {}));
    expect(find.byType(OutlinedButton), findsOneWidget);

    await pump(tester, AppButton.text(label: '건너뛰기', onPressed: () {}));
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets('로딩 중이면 스피너를 그리고 누를 수 없다', (tester) async {
    var tapped = 0;
    await pump(
      tester,
      AppButton.primary(
        label: '저장',
        onPressed: () => tapped++,
        isLoading: true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('저장'), findsNothing);
    await tester.tap(find.byType(AppButton));
    expect(tapped, 0);
  });

  testWidgets('기본값이면 전환 위젯 없이 바로 바뀐다', (tester) async {
    await pump(tester, AppButton.primary(label: '저장', onPressed: () {}));
    await pump(
      tester,
      AppButton.primary(label: '저장', onPressed: () {}, isLoading: true),
    );

    expect(inButton(AnimatedSwitcher), findsNothing);
    expect(find.text('저장'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  for (final (name, build) in [
    ('primary', AppButton.primary),
    ('secondary', AppButton.secondary),
  ]) {
    testWidgets('$name: animateLoading 이면 라벨과 스피너가 겹쳐 넘어간다', (tester) async {
      await pump(
        tester,
        build(label: '저장', onPressed: () {}, animateLoading: true),
      );
      await pump(
        tester,
        build(
          label: '저장',
          onPressed: () {},
          isLoading: true,
          animateLoading: true,
        ),
      );

      expect(inButton(AnimatedSwitcher), findsOneWidget);
      expect(inButton(FadeTransition), findsWidgets);
      // 전환 중에는 나가는 라벨과 들어오는 스피너가 함께 있다.
      expect(find.text('저장'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 스피너는 계속 돌아 pumpAndSettle 이 끝나지 않으므로 전환 시간을 넘겨
      // 흘린다. 딱 맞춰 끝나는 프레임에서는 컨트롤러가 아직 완료로 바뀌지 않는다.
      await tester.pump(AppMotion.medium);
      await tester.pump(AppMotion.medium);

      expect(find.text('저장'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await pump(
        tester,
        build(label: '저장', onPressed: () {}, animateLoading: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('저장'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('애니메이션 줄이기면 animateLoading 이어도 바로 바뀐다', (tester) async {
    await pump(
      tester,
      AppButton.primary(label: '저장', onPressed: () {}, animateLoading: true),
      disableAnimations: true,
    );
    await pump(
      tester,
      AppButton.primary(
        label: '저장',
        onPressed: () {},
        isLoading: true,
        animateLoading: true,
      ),
      disableAnimations: true,
    );

    expect(inButton(AnimatedSwitcher), findsNothing);
    expect(find.text('저장'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
