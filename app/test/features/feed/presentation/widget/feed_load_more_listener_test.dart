import 'package:daylog/features/feed/presentation/widget/feed_load_more_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 가로 목록 한 칸 · 세로 목록 한 칸의 크기. 화면(600x800)보다 큰 길이를
/// 만들어 실제로 스크롤이 일어나게 한다.
const _itemExtent = 200.0;

void main() {
  late int calls;

  setUp(() => calls = 0);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FeedLoadMoreListener(onLoadMore: () => calls++, child: child),
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

    // 세로 목록은 첫 화면 그대로다. 사진만 오른쪽 끝까지 넘긴다.
    await tester.drag(
      find.byKey(const ValueKey('가로 0')),
      const Offset(-2000, 0),
    );
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('중첩된 세로 목록(depth > 0)의 알림도 요청하지 않는다', (tester) async {
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
          // 바깥 목록은 화면보다 길어 끝에서 멀리 있다.
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
