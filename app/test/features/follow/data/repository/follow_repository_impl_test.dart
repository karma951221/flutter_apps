import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/follow/data/cursor/follow_cursor.dart';
import 'package:daylog/features/follow/data/datasource/follow_data_source.dart';
import 'package:daylog/features/follow/data/dto/follow_user_dto.dart';
import 'package:daylog/features/follow/data/repository/follow_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFollowDataSource extends Mock implements FollowDataSource {}

FollowUserDto _dto(int index) => FollowUserDto(
  id: 'user-$index',
  nickname: '사람 $index',
  createdAt: DateTime.utc(2026, 8, 30, 9).subtract(Duration(minutes: index)),
);

void main() {
  late _MockFollowDataSource dataSource;
  late FollowRepositoryImpl repository;

  setUp(() {
    dataSource = _MockFollowDataSource();
    repository = FollowRepositoryImpl(dataSource);
  });

  test('다음 페이지 유무를 알려고 한 개를 더 요청한다', () async {
    when(
      () => dataSource.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getFollowers(userId: 'u1', limit: 20);

    verify(
      () => dataSource.getFollowers(userId: 'u1', limit: 21, cursor: null),
    ).called(1);
  });

  test('요청한 개수보다 많이 오면 잘라내고 다음 커서를 만든다', () async {
    when(
      () => dataSource.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => [for (var i = 0; i < 3; i++) _dto(i)]);

    final result = await repository.getFollowers(userId: 'u1', limit: 2);

    final page = (result as Ok).value;
    expect(page.items.length, 2);
    expect(page.hasMore, isTrue);
    // 커서는 잘라낸 뒤의 마지막 항목이다 — 그다음 페이지가 그 자리에서 이어진다.
    expect(FollowCursor.decode(page.nextCursor)!.id, 'user-1');
  });

  test('요청한 개수 이하로 오면 마지막 페이지다', () async {
    when(
      () => dataSource.getFollowings(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => [_dto(0)]);

    final result = await repository.getFollowings(userId: 'u1', limit: 20);

    expect((result as Ok).value.hasMore, isFalse);
  });

  test('받은 커서를 해석해 데이터 원천에 넘긴다', () async {
    final cursor = FollowCursor(
      createdAt: DateTime.utc(2026, 8, 30, 9),
      id: 'user-9',
    );
    when(
      () => dataSource.getFollowings(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => []);

    await repository.getFollowings(
      userId: 'u1',
      limit: 20,
      cursor: cursor.encode(),
    );

    verify(
      () => dataSource.getFollowings(userId: 'u1', limit: 21, cursor: cursor),
    ).called(1);
  });

  test('깨진 커서는 Err 로 돌려준다', () async {
    final result = await repository.getFollowers(
      userId: 'u1',
      limit: 20,
      cursor: 'not-a-cursor',
    );

    expect((result as Err).failure, isA<ValidationFailure>());
    verifyNever(
      () => dataSource.getFollowers(
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    );
  });

  test('팔로우·해제 실패는 Err 로 옮긴다', () async {
    when(
      () => dataSource.followUser('u1'),
    ).thenThrow(const Failure.forbidden(message: '거부'));

    final result = await repository.followUser('u1');

    expect((result as Err).failure, isA<ForbiddenFailure>());
  });
}
