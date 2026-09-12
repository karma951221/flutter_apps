import 'package:core/core.dart';
import '../entity/avatar_image_draft.dart';
import '../entity/profile.dart';
import '../entity/profile_update.dart';

/// 프로필 저장소.
///
/// 인증된 사용자의 식별은 구현체가 처리한다. 따라서 presentation은 Supabase 세션이나
/// 현재 사용자 ID를 알 필요가 없다.
abstract interface class ProfileRepository {
  /// 사용자 ID로 공개 프로필을 조회한다.
  Future<Result<Profile>> getProfile(String userId);

  /// 로그인한 사용자의 프로필을 조회한다.
  Future<Result<Profile>> getMyProfile();

  /// 로그인한 사용자의 프로필을 수정한다.
  Future<Result<Profile>> updateMyProfile(ProfileUpdate update);

  /// 닉네임 사용 가능 여부. UI 안내용이며 최종 보장은 DB unique 제약이 맡는다.
  Future<Result<bool>> isNicknameAvailable(String nickname);

  /// 아바타 이미지를 올리고 공개 URL 을 돌려준다.
  ///
  /// 버킷 이름과 경로 규칙은 data 계층이 안다. scenario 는 URL 만 받아
  /// [ProfileUpdate.avatarUrl] 에 담는다.
  Future<Result<String>> uploadAvatar(AvatarImageDraft image);

  /// 공개 URL 이 가리키는 아바타 객체를 지운다.
  ///
  /// 교체된 옛 이미지나 저장에 실패한 새 이미지를 치우는 용도라 best-effort 다.
  /// 실패해도 저장 결과를 뒤집지 않으므로 `Result` 를 돌려주지 않는다.
  Future<void> removeAvatar(String? publicUrl);
}
