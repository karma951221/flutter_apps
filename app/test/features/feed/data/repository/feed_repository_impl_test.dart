import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/feed/data/cursor/feed_cursor.dart';
import 'package:daylog/features/feed/data/datasource/feed_data_source.dart';
import 'package:daylog/features/feed/data/dto/feed_post_dto.dart';
import 'package:daylog/features/feed/data/repository/feed_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeedDataSource extends Mock implements FeedDataSource {}

FeedPostDto _dto(int index) => FeedPostDto(
  id: 'post-$index',
  authorId: 'author-id',
  content: '기록 $index',
  createdAt: DateTime.utc(2026, 8, 22, 9).subtract(Duration(minutes: index)),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

void main() {
  late _MockFeedDataSource dataSource;
  late FeedRepositoryImpl repository;

  setUp(() {
    dataSource = _MockFeedDataSource();
    repository = FeedRepositoryImpl(dataSource);
  });

  test('다음 페이지 유무를 알려고 한 개를 더 요청한다', () async {
    when(
      () => dataSource.getPosts(limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);

    await repository.getPosts(limit: 20);

    verify(() => dataSource.getPosts(limit: 21, cursor: null)).called(1);
  });

  test('요청한 개수보다 많이 오면 잘라내고 다음 커서를 만든다', () async {
    when(
      () => dataSource.getPosts(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [_dto(0), _dto(1), _dto(2)]);

    final page = ((await repository.getPosts(limit: 2)) as Ok).value;

    expect(page.items.length, 2);
    expect(page.items.last.id, 'post-1');
    expect(page.hasMore, isTrue);
    // 커서는 마지막으로 **돌려준** 항목 기준이어야 한다. 잘라낸 항목 기준이면
    // 다음 페이지에서 한 건이 건너뛰어진다.
    expect(FeedCursor.decode(page.nextCursor)!.id, 'post-1');
  });

  test('요청한 개수 이하로 오면 마지막 페이지다', () async {
    when(
      () => dataSource.getPosts(limit: any(named: 'limit')),
    ).thenAnswer((_) async => [_dto(0)]);

    final page = ((await repository.getPosts(limit: 20)) as Ok).value;

    expect(page.items.length, 1);
    expect(page.hasMore, isFalse);
    expect(page.nextCursor, isNull);
  });

  test('빈 결과도 마지막 페이지로 다룬다', () async {
    when(
      () => dataSource.getPosts(limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);

    final page = ((await repository.getPosts(limit: 20)) as Ok).value;

    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
  });

  test('받은 커서를 해석해 데이터 원천에 넘긴다', () async {
    final cursor = FeedCursor(
      createdAt: DateTime.utc(2026, 8, 22, 9),
      id: 'post-9',
    );
    when(
      () => dataSource.getPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getPosts(limit: 20, cursor: cursor.encode());

    verify(() => dataSource.getPosts(limit: 21, cursor: cursor)).called(1);
  });

  test('깨진 커서는 Err 로 돌려준다', () async {
    final result = await repository.getPosts(limit: 20, cursor: 'broken!!');

    expect(result, isA<Err>());
    verifyNever(
      () => dataSource.getPosts(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    );
  });
}
