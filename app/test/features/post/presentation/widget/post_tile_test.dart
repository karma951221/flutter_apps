import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/post/domain/entity/post.dart';
import 'package:daylog/features/post/domain/entity/post_author.dart';
import 'package:daylog/features/post/presentation/widget/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _author = PostAuthor(id: 'author-1', nickname: '카르마');

Post _post() => Post(
  id: 'post-1',
  authorId: 'author-1',
  content: '오늘의 기록',
  createdAt: DateTime.utc(2026, 8, 23, 9),
  updatedAt: DateTime.utc(2026, 8, 23, 9),
);

Future<void> _pump(
  WidgetTester tester, {
  required bool isMine,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onReport,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: PostTile(
        post: _post(),
        author: _author,
        isMine: isMine,
        onTap: () {},
        onEdit: onEdit,
        onDelete: onDelete,
        onReport: onReport,
      ),
    ),
  ),
);

void main() {
  testWidgets('내 글에는 수정 · 삭제가 뜨고 신고가 없다', (tester) async {
    await _pump(
      tester,
      isMine: true,
      onEdit: () {},
      onDelete: () {},
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('수정'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('신고'), findsNothing);
  });

  testWidgets('남의 글에는 신고가 뜨고 수정 · 삭제가 없다', (tester) async {
    await _pump(tester, isMine: false, onReport: () {});

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsOneWidget);
    expect(find.text('수정'), findsNothing);
    expect(find.text('삭제'), findsNothing);
  });

  testWidgets('신고를 고르면 onReport 가 불린다', (tester) async {
    var reported = false;
    await _pump(
      tester,
      isMine: false,
      onReport: () => reported = true,
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();

    expect(reported, isTrue);
  });

  testWidgets('콜백이 모두 null 이면 메뉴가 안 그려진다', (tester) async {
    await _pump(tester, isMine: false);

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
