import 'dart:typed_data';

import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/profile/domain/entity/avatar_image_draft.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/entity/profile_update.dart';
import 'package:daylog/features/profile/domain/repository/profile_repository.dart';
import 'package:daylog/features/profile/domain/usecase/scenario/update_avatar_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _newUrl = 'https://x.supabase.co/storage/v1/object/public/avatars/u1/2.webp';
const _oldUrl = 'https://x.supabase.co/storage/v1/object/public/avatars/u1/1.webp';

final _avatar = AvatarImageDraft(
  bytes: Uint8List.fromList([1, 2, 3]),
  contentType: 'image/webp',
  extension: 'webp',
);

final _profile = Profile(
  id: 'u1',
  nickname: 'daylog',
  bio: '오늘의 기록',
  avatarUrl: _newUrl,
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 10),
);

const _update = ProfileUpdate(
  nickname: 'daylog',
  bio: '오늘의 기록',
  avatarUrl: _oldUrl,
);

void main() {
  late _MockProfileRepository repository;

  setUpAll(() {
    registerFallbackValue(const ProfileUpdate(nickname: 'fallback'));
    registerFallbackValue(
      AvatarImageDraft(
        bytes: Uint8List(0),
        contentType: 'image/webp',
        extension: 'webp',
      ),
    );
  });

  setUp(() {
    repository = _MockProfileRepository();
    when(() => repository.removeAvatar(any())).thenAnswer((_) async {});
  });

  test('업로드한 URL 로 프로필을 갱신하고 이전 이미지를 지운다', () async {
    when(
      () => repository.uploadAvatar(any()),
    ).thenAnswer((_) async => const Ok(_newUrl));
    when(
      () => repository.updateMyProfile(any()),
    ).thenAnswer((_) async => Ok(_profile));

    final result = await UpdateAvatarScenario(
      repository,
    )(_update, newAvatar: _avatar);

    expect(result, isA<Ok<Profile>>());
    final sent =
        verify(() => repository.updateMyProfile(captureAny())).captured.single
            as ProfileUpdate;
    // 화면이 넘긴 현재 URL 대신 방금 올린 URL 이 저장된다.
    expect(sent.avatarUrl, _newUrl);
    verify(() => repository.removeAvatar(_oldUrl)).called(1);
    verifyNever(() => repository.removeAvatar(_newUrl));
  });

  test('프로필 갱신이 실패하면 방금 올린 이미지를 되돌린다', () async {
    const failure = Failure.validation(message: '이미 사용 중인 닉네임입니다');
    when(
      () => repository.uploadAvatar(any()),
    ).thenAnswer((_) async => const Ok(_newUrl));
    when(
      () => repository.updateMyProfile(any()),
    ).thenAnswer((_) async => const Err(failure));

    final result = await UpdateAvatarScenario(
      repository,
    )(_update, newAvatar: _avatar);

    expect((result as Err<Profile>).failure, failure);
    // 보상: 새 객체만 지우고 이전 아바타는 그대로 둔다.
    verify(() => repository.removeAvatar(_newUrl)).called(1);
    verifyNever(() => repository.removeAvatar(_oldUrl));
  });

  test('업로드가 실패하면 프로필을 건드리지 않는다', () async {
    when(() => repository.uploadAvatar(any())).thenAnswer(
      (_) async => const Err(Failure.network(message: '오프라인')),
    );

    final result = await UpdateAvatarScenario(
      repository,
    )(_update, newAvatar: _avatar);

    expect(
      (result as Err<Profile>).failure.message,
      '프로필 사진을 업로드하지 못했습니다.',
    );
    verifyNever(() => repository.updateMyProfile(any()));
    verifyNever(() => repository.removeAvatar(any()));
  });

  test('새 이미지가 없으면 저장소의 이미지 호출이 한 번도 없다', () async {
    when(
      () => repository.updateMyProfile(any()),
    ).thenAnswer((_) async => Ok(_profile));

    final result = await UpdateAvatarScenario(repository)(_update);

    expect(result, isA<Ok<Profile>>());
    verify(() => repository.updateMyProfile(_update)).called(1);
    verifyNever(() => repository.uploadAvatar(any()));
    verifyNever(() => repository.removeAvatar(any()));
  });
}
