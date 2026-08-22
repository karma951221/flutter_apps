import '../../../../core/result/result.dart';
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
}
