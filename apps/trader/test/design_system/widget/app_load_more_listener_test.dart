import 'package:daylog/design_system/widget/app_load_more_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _itemExtent = 200.0;

void main() {
  late int calls;

  setUp(() => calls = 0);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppLoadMoreListener(onLoadMore: () => calls++, child: child),
      ),
    ),
  );

  testWidgets('세로 목록이 끝에 가까워지면 다음 페이지를 요청한다', (tester) async {
    await pump(
      tester,
      ListView.builder(
        itemCount: 10,
        itemBuilder: (_, index) =>
            SizedBox(height: _itemExtent, child: Text('세로 $index')),
      ),
    );

    expect(calls, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(calls, greaterThan(0));
  });

  testWidgets('안에 든 가로 목록을 끝까지 넘겨도 요청하지 않는다', (tester) async {
    await pump(
      tester,
      ListView.builder(
        itemCount: 10,
        itemBuilder: (_, index) => SizedBox(
          height: _itemExtent,
          child: ListView.builder(
            key: ValueKey('가로 $index'),
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (_, column) =>
                SizedBox(width: _itemExtent, child: Text('사진 $index-$column')),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('가로 0')),
      const Offset(-2000, 0),
    );
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('중첩된 세로 목록의 알림도 요청하지 않는다', (tester) async {
    await pump(
      tester,
      ListView(
        children: [
          SizedBox(
            height: _itemExtent,
            child: ListView.builder(
              key: const ValueKey('안쪽 세로'),
              itemCount: 5,
              itemBuilder: (_, index) =>
                  SizedBox(height: _itemExtent, child: Text('안쪽 $index')),
            ),
          ),
          const SizedBox(height: 2000),
        ],
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('안쪽 세로')),
      const Offset(0, -2000),
    );
    await tester.pump();
    expect(calls, 0);
  });
}
