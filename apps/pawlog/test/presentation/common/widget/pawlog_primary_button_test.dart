import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/presentation/common/widget/pawlog_primary_button.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget button, {
  bool disableAnimations = false,
}) => tester.pumpWidget(
  MaterialApp(
    theme: PawlogTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: PawlogBottomAction(child: button)),
    ),
  ),
);

double _opacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

double _scale(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

Color? _background(WidgetTester tester) => tester
    .widget<FilledButton>(find.byType(FilledButton))
    .style!
    .backgroundColor!
    .resolve({});

void main() {
  testWidgets('알약 58 높이에 남색이고 누르면 onPressed 를 부른다', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      PawlogPrimaryButton(label: '산책 시작', onPressed: () => taps++),
    );

    expect(tester.getSize(find.byType(FilledButton)).height, 58);
    expect(_background(tester), PawlogColors.light.primary);
    expect(_opacity(tester), 1);

    await tester.tap(find.text('산책 시작'));
    expect(taps, 1);
  });

  testWidgets('누르는 동안 0.97 로 줄었다가 떼면 돌아온다', (tester) async {
    await _pump(tester, PawlogPrimaryButton(label: '시작', onPressed: () {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    expect(_scale(tester), PawlogMotion.pressedScale);

    await gesture.up();
    await tester.pump();
    expect(_scale(tester), 1);
  });

  testWidgets('비활성은 투명도 0.4 이고 눌러도 줄지 않는다', (tester) async {
    await _pump(
      tester,
      const PawlogPrimaryButton(label: '시작', onPressed: null),
    );

    expect(_opacity(tester), PawlogMotion.disabledOpacity);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FilledButton)),
    );
    await tester.pump();
    expect(_scale(tester), 1);
    await gesture.up();
  });

  testWidgets('로딩은 흐리지 않고 라벨을 진행 표시로 200ms 에 걸쳐 바꾼다', (tester) async {
    var taps = 0;
    Widget button({required bool loading}) => PawlogPrimaryButton(
      label: '저장',
      isLoading: loading,
      onPressed: () => taps++,
    );
    await _pump(tester, button(loading: false));
    await _pump(tester, button(loading: true));

    // 크로스페이드 중에는 둘 다 있다.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('저장'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 진행 표시는 끝없이 돌아 settle 하지 않는다 — 전환 시간만큼만 흘린다.
    await tester.pump(PawlogMotion.state);
    expect(find.text('저장'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(_opacity(tester), 1);

    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('애니메이션 줄이기면 로딩 전환이 즉시 끝난다', (tester) async {
    Widget button({required bool loading}) =>
        PawlogPrimaryButton(label: '저장', isLoading: loading, onPressed: () {});
    await _pump(tester, button(loading: false), disableAnimations: true);
    await _pump(tester, button(loading: true), disableAnimations: true);
    await tester.pump();

    expect(find.text('저장'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('끝내기 변형은 먹색이다', (tester) async {
    await _pump(
      tester,
      PawlogPrimaryButton.stop(label: '산책 종료', onPressed: () {}),
    );

    expect(_background(tester), PawlogColors.light.stop);
  });
}
