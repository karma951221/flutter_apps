import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/shell/widget/system_bar_bottom_padding.dart';

void main() {
  const bodyKey = ValueKey('body');

  /// 셸과 같은 모양 — Scaffold 하단 바에 [SystemBarBottomPadding] 으로 감싼 NavigationBar.
  Widget shell(MediaQueryData media, {bool guard = true}) {
    final bar = NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'a'),
        NavigationDestination(icon: Icon(Icons.chat), label: 'b'),
      ],
    );
    return MaterialApp(
      home: MediaQuery(
        data: media,
        child: Scaffold(
          body: const SizedBox.expand(key: bodyKey),
          bottomNavigationBar: guard ? SystemBarBottomPadding(child: bar) : bar,
        ),
      ),
    );
  }

  const size = Size(400, 800);
  const navBar = 48.0;
  const keyboard = 300.0;

  /// 키보드가 닫힌 상태. Flutter 는 `padding = viewPadding - viewInsets` 로 만든다.
  const closed = MediaQueryData(
    size: size,
    viewPadding: EdgeInsets.only(bottom: navBar),
    padding: EdgeInsets.only(bottom: navBar),
  );

  /// 키보드는 닫혔는데 IME inset 이 남은(stale) 상태 — padding.bottom 이 0 으로 먹혔다.
  const stale = MediaQueryData(
    size: size,
    viewPadding: EdgeInsets.only(bottom: navBar),
    viewInsets: EdgeInsets.only(bottom: keyboard),
  );

  void sizeView(WidgetTester tester) {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  double barBottomGap(WidgetTester tester) =>
      size.height -
      tester.getBottomLeft(find.byType(NavigationDestination).first).dy;

  testWidgets('IME inset 이 남아도 탭바 내용은 시스템 내비 위에 그린다', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(shell(closed));
    final normal = barBottomGap(tester);
    final normalHeight = tester.getSize(find.byType(NavigationBar)).height;

    await tester.pumpWidget(shell(stale));

    expect(barBottomGap(tester), normal);
    expect(tester.getSize(find.byType(NavigationBar)).height, normalHeight);
  });

  testWidgets('감싸지 않으면 stale inset 에서 탭바가 시스템 내비 밑으로 내려간다(회귀 기준)', (
    tester,
  ) async {
    sizeView(tester);
    await tester.pumpWidget(shell(closed, guard: false));
    final normal = barBottomGap(tester);

    await tester.pumpWidget(shell(stale, guard: false));

    expect(barBottomGap(tester), lessThan(normal));
  });

  testWidgets('키보드가 닫혀 inset 이 없으면 아무것도 바꾸지 않는다', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(shell(closed));

    final inner = MediaQuery.of(tester.element(find.byType(NavigationBar)));
    expect(inner.padding.bottom, navBar);
  });

  testWidgets('키보드가 정말 열려도 몸통 높이는 지금과 같다(탭바는 키보드 뒤)', (tester) async {
    sizeView(tester);
    await tester.pumpWidget(shell(stale, guard: false));
    final before = tester.getSize(find.byKey(bodyKey)).height;

    await tester.pumpWidget(shell(stale));

    expect(tester.getSize(find.byKey(bodyKey)).height, before);
    expect(before, size.height - keyboard);
  });
}
