import 'package:core/core.dart';
import 'package:daylog/features/profile/data/datasource/profile_data_source.dart';
import 'package:daylog/features/profile/data/dto/profile_dto.dart';
import 'package:daylog/features/profile/data/repository/profile_repository_impl.dart';
import 'package:daylog/features/profile/domain/entity/profile_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockProfileDataSource extends Mock implements ProfileDataSource {}

final _dto = ProfileDto(
  id: 'profile-id',
  nickname: 'daylog',
  bio: '오늘의 기록',
  avatarUrl: 'https://example.com/avatar.webp',
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
);

void main() {
  late _MockProfileDataSource dataSource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    dataSource = _MockProfileDataSource();
    repository = ProfileRepositoryImpl(dataSource);
  });

  test('타인 프로필 DTO를 domain Profile로 변환한다', () async {
    when(
      () => dataSource.getProfile('profile-id'),
    ).thenAnswer((_) async => _dto);

    final result = await repository.getProfile('profile-id');

    expect(result, isA<Ok>());
    final profile = (result as Ok).value;
    expect(profile.id, _dto.id);
    expect(profile.nickname, _dto.nickname);
    expect(profile.avatarUrl, _dto.avatarUrl);
    verify(() => dataSource.getProfile('profile-id')).called(1);
  });

  test('data source의 Failure는 변환하지 않고 그대로 반환한다', () async {
    const failure = Failure.network(message: '오프라인');
    when(() => dataSource.getProfile(any())).thenThrow(failure);

    final result = await repository.getProfile('profile-id');

    expect(result, isA<Err>());
    expect((result as Err).failure, failure);
  });

  test('Supabase 권한 오류를 ForbiddenFailure로 변환한다', () async {
    when(() => dataSource.getProfile(any())).thenThrow(
      PostgrestException(message: 'permission denied', code: '42501'),
    );

    final result = await repository.getProfile('profile-id');

    expect(result, isA<Err>());
    expect((result as Err).failure, isA<ForbiddenFailure>());
  });

  test('로그인한 사용자가 없으면 내 프로필 조회를 인증 오류로 반환한다', () async {
    when(dataSource.getMyProfile).thenAnswer((_) async => null);

    final result = await repository.getMyProfile();

    expect(result, isA<Err>());
    final failure = (result as Err).failure;
    expect(failure, isA<AuthFailure>());
    expect((failure as AuthFailure).code, 'not_authenticated');
  });

  test('내 프로필 수정 결과를 Profile로 반환하고 명령을 그대로 전달한다', () async {
    const update = ProfileUpdate(
      nickname: 'new-daylog',
      bio: '새 소개',
      avatarUrl: 'https://example.com/new.webp',
    );
    when(
      () => dataSource.updateMyProfile(update),
    ).thenAnswer((_) async => _dto.copyWith(nickname: 'new-daylog'));

    final result = await repository.updateMyProfile(update);

    expect(result, isA<Ok>());
    expect((result as Ok).value.nickname, 'new-daylog');
    verify(() => dataSource.updateMyProfile(update)).called(1);
  });

  test('닉네임 중복 확인 결과를 변경 없이 전달한다', () async {
    when(
      () => dataSource.isNicknameAvailable('daylog'),
    ).thenAnswer((_) async => false);

    final result = await repository.isNicknameAvailable('daylog');

    expect(result, isA<Ok<bool>>());
    expect((result as Ok<bool>).value, isFalse);
    verify(() => dataSource.isNicknameAvailable('daylog')).called(1);
  });
}
