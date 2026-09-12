import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/safety/data/datasource/block_data_source.dart';
import 'package:daylog/features/safety/data/dto/blocked_user_dto.dart';
import 'package:daylog/features/safety/data/repository/block_repository_impl.dart';
import 'package:daylog/features/safety/domain/entity/blocked_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBlockDataSource extends Mock implements BlockDataSource {}

void main() {
  late _MockBlockDataSource dataSource;
  late BlockRepositoryImpl repository;

  setUp(() {
    dataSource = _MockBlockDataSource();
    repository = BlockRepositoryImpl(dataSource);
  });

  group('blockUser', () {
    test('성공하면 Ok 를 돌려준다', () async {
      when(() => dataSource.blockUser('user-1')).thenAnswer((_) async {});

      final result = await repository.blockUser('user-1');

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.blockUser('user-1')).called(1);
    });

    test('자기 차단(blocks_not_self) 은 ValidationFailure 로 변환된다', () async {
      when(() => dataSource.blockUser(any())).thenThrow(
        PostgrestException(
          message:
              'new row for relation "blocks" violates check constraint '
              '"blocks_not_self"',
          code: '23514',
        ),
      );

      final result = await repository.blockUser('user-1');

      expect(result, isA<Err<void>>());
      final failure = (result as Err<void>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '자기 자신은 차단할 수 없습니다');
    });

    test('중복 차단(blocks_pkey) 은 ValidationFailure 로 변환된다', () async {
      when(() => dataSource.blockUser(any())).thenThrow(
        PostgrestException(
          message:
              'duplicate key value violates unique constraint "blocks_pkey"',
          code: '23505',
        ),
      );

      final result = await repository.blockUser('user-1');

      expect(result, isA<Err<void>>());
      final failure = (result as Err<void>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).message, '이미 차단한 사용자입니다');
    });

    test('data source 의 Failure 는 변환하지 않고 그대로 반환한다', () async {
      const failure = Failure.auth(message: '로그인이 필요합니다');
      when(() => dataSource.blockUser(any())).thenThrow(failure);

      final result = await repository.blockUser('user-1');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, failure);
    });
  });

  group('unblockUser', () {
    test('성공하면 Ok 를 돌려준다', () async {
      when(() => dataSource.unblockUser('user-1')).thenAnswer((_) async {});

      final result = await repository.unblockUser('user-1');

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.unblockUser('user-1')).called(1);
    });
  });

  group('getBlockedUsers', () {
    test('DTO 목록을 domain BlockedUser 목록으로 변환한다', () async {
      final dtos = [
        BlockedUserDto(
          id: 'user-1',
          nickname: 'daylog',
          avatarUrl: 'https://example.com/avatar.webp',
          createdAt: DateTime.utc(2026, 8, 25, 9),
        ),
      ];
      when(dataSource.getBlockedUsers).thenAnswer((_) async => dtos);

      final result = await repository.getBlockedUsers();

      expect(result, isA<Ok<List<BlockedUser>>>());
      final users = (result as Ok<List<BlockedUser>>).value;
      expect(users, hasLength(1));
      expect(users.first.id, 'user-1');
      expect(users.first.nickname, 'daylog');
    });

    test('예외는 SupabaseErrorMapper 로 변환된다', () async {
      when(dataSource.getBlockedUsers).thenThrow(
        PostgrestException(message: 'permission denied', code: '42501'),
      );

      final result = await repository.getBlockedUsers();

      expect(result, isA<Err<List<BlockedUser>>>());
      expect(
        (result as Err<List<BlockedUser>>).failure,
        isA<ForbiddenFailure>(),
      );
    });
  });

  group('isBlockedByMe', () {
    test('data source 의 결과를 그대로 전달한다', () async {
      when(
        () => dataSource.isBlockedByMe('user-1'),
      ).thenAnswer((_) async => true);

      final result = await repository.isBlockedByMe('user-1');

      expect(result, isA<Ok<bool>>());
      expect((result as Ok<bool>).value, isTrue);
    });
  });
}
