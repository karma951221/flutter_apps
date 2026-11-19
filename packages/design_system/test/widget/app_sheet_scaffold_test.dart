import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, WidgetBuilder builder) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showAppSheet<void>(context: context, builder: builder),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('손잡이 · titleLarge 제목 · 설명 · 내용을 그린다', (tester) async {
    await open(
      tester,
      (_) => const AppSheetScaffold(
        title: '제목',
        description: '설명',
        children: [ListTile(title: Text('행'))],
      ),
    );

    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(bottomSheet.showDragHandle, isTrue);
    final context = tester.element(find.text('제목'));
    final title = tester.widget<Text>(find.text('제목'));
    expect(title.style, Theme.of(context).textTheme.titleLarge);
    expect(find.text('설명'), findsOneWidget);
    // 제목과 행 글자 줄이 같은 왼쪽 선에 선다.
    expect(
      tester.getTopLeft(find.text('행')).dx,
      tester.getTopLeft(find.text('제목')).dx,
    );
  });

  testWidgets('버튼 둘은 나란히, 주 버튼이 오른쪽이다', (tester) async {
    await open(
      tester,
      (_) => AppSheetScaffold(
        title: '제목',
        primaryAction: AppButton.primary(label: '저장', onPressed: () {}),
        secondaryAction: AppButton.secondary(label: '취소', onPressed: () {}),
        children: const [],
      ),
    );

    final save = tester.getCenter(find.text('저장'));
    final cancel = tester.getCenter(find.text('취소'));
    expect(save.dy, cancel.dy);
    expect(save.dx, greaterThan(cancel.dx));
  });

  testWidgets('내용이 길면 내용만 스크롤되고 끌기형은 목록을 끌 수 있다', (tester) async {
    await open(
      tester,
      (_) => AppSheetScaffold.draggable(
        title: '긴 목록',
        children: [for (var i = 0; i < 50; i++) ListTile(title: Text('행 $i'))],
      ),
    );

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('긴 목록'), findsOneWidget);
    expect(find.text('행 49'), findsNothing);
  });

  testWidgets('키보드가 올라오면 그만큼 밀린다', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await open(
      tester,
      (_) => const AppSheetScaffold(title: '입력', children: [TextField()]),
    );

    final screen = tester.getSize(find.byType(MaterialApp));
    expect(
      tester.getBottomLeft(find.byType(TextField)).dy,
      lessThan(screen.height - 300 / tester.view.devicePixelRatio),
    );
  });

  testWidgets('AppSheetHandle 은 모달 손잡이와 같은 크기다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppSheetHandle()),
      ),
    );
    final box = find.descendant(
      of: find.byType(AppSheetHandle),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(box.last), const Size(32, 4));
  });
}
