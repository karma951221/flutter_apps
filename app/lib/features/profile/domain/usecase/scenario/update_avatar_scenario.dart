import '../../../../../core/error/failure.dart';
import '../../../../../core/result/result.dart';
import '../../entity/avatar_image_draft.dart';
import '../../entity/profile.dart';
import '../../entity/profile_update.dart';
import '../../repository/profile_repository.dart';
import 'update_my_profile_scenario.dart';

/// 아바타를 바꾸며 프로필을 저장하는 흐름.
///
/// 업로드 → 프로필 갱신 → 정리 순서로 진행한다. 업로드가 갱신보다 앞서야 새
/// URL 을 같은 요청에 담을 수 있다. 갱신이 실패하면 방금 올린 객체를, 성공하면
/// 이전 객체를 치운다. Storage 는 DB 트랜잭션 밖이라 이 보상 처리를 앱이 직접
/// 해야 한다.
///
/// 저장소 호출을 여러 번 조합하고 보상까지 하는 흐름이므로 화면이 아니라
/// scenario 가 소유한다 (규칙 ③). Storage 능력은 [ProfileRepository] 를 통해서만
/// 닿는다 — scenario 가 `ImageStorage` 를 직접 주입받으면 domain 이 core 의
/// 저장소 구현 관심사(버킷 이름, 공개 URL 규칙)를 알게 되고, 업로드 실패를
/// `Failure` 로 바꾸는 지점도 data 계층 밖으로 새어나간다 (규칙 ④·⑤).
class UpdateAvatarScenario {
  const UpdateAvatarScenario(this._repository);

  final ProfileRepository _repository;

  /// [newAvatar] 가 없으면 평범한 프로필 저장이다 — 저장소의 이미지 호출은
  /// 한 번도 일어나지 않는다.
  ///
  /// [update]`.avatarUrl` 은 **현재** 아바타 URL 이다. 업로드가 끝나면 새 URL 로
  /// 바꿔 저장하고, 원래 값은 성공 뒤 지울 대상이 된다.
  Future<Result<Profile>> call(
    ProfileUpdate update, {
    AvatarImageDraft? newAvatar,
  }) async {
    if (newAvatar == null) return UpdateMyProfileScenario(_repository)(update);

    final String newAvatarUrl;
    switch (await _repository.uploadAvatar(newAvatar)) {
      case Ok<String>(:final value):
        newAvatarUrl = value;
      case Err<String>():
        return const Err(_uploadFailure);
    }
    final previousAvatarUrl = update.avatarUrl;

    final result = await UpdateMyProfileScenario(
      _repository,
    )(update.copyWith(avatarUrl: newAvatarUrl));

    // 정리는 best-effort 다. 실패해도 저장 결과를 뒤집지 않는다.
    switch (result) {
      case Ok<Profile>():
        await _repository.removeAvatar(previousAvatarUrl);
      case Err<Profile>():
        await _repository.removeAvatar(newAvatarUrl);
    }
    return result;
  }

  /// 업로드 실패는 원인을 가리지 않고 한 문구로 알린다. 사용자가 할 수 있는
  /// 일이 "다시 시도" 하나뿐이라, 저장소 오류 문구를 그대로 보여줄 이유가 없다.
  static const _uploadFailure = Failure.unknown(
    message: '프로필 사진을 업로드하지 못했습니다.',
  );
}
