import '../../../../core/result/result.dart';
import '../entity/app_user.dart';

/// 인증 저장소.
///
/// 구현체는 현재 Supabase 하나뿐이지만, 나중에 자체 백엔드로 교체할 때
/// 이 인터페이스만 다시 구현하면 presentation 계층은 손대지 않는다.
abstract interface class AuthRepository {
  /// 로그인 상태 변화. 로그인/로그아웃/토큰갱신/세션복구에서 흐른다.
  /// 미인증이면 null 을 흘린다.
  Stream<AppUser?> authStateChanges();

  /// 앱 시작 시점의 사용자. 저장된 세션이 없으면 null.
  Future<AppUser?> currentUser();

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// 계정과 계정에 딸린 모든 것을 지운다. 성공하면 세션도 함께 사라진다.
  Future<Result<void>> deleteAccount();

  /// 닉네임 사용 가능 여부. 가입 전 확인용.
  ///
  /// 이건 UX 용이다. 최종 보장은 DB 의 unique 제약이 한다.
  Future<Result<bool>> isNicknameAvailable(String nickname);

  // --- 비밀번호 재설정 (3단계) ---

  /// 1) 재설정 코드를 메일로 보낸다.
  Future<Result<void>> sendPasswordResetCode(String email);

  /// 2) 코드를 검증한다. 성공하면 임시 세션이 생겨 비밀번호를 바꿀 수 있다.
  Future<Result<void>> verifyPasswordResetCode({
    required String email,
    required String code,
  });

  /// 3) 새 비밀번호로 교체한다.
  Future<Result<void>> updatePassword(String newPassword);
}
