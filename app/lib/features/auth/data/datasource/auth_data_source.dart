import '../dto/auth_user_dto.dart';

/// 인증 원격 데이터 원천의 계약.
///
/// SDK 타입과 세션 접근은 이 계층에만 둔다.
abstract interface class AuthDataSource {
  Stream<AuthUserDto?> authStateChanges();
  Future<AuthUserDto?> currentUser();
  Future<AuthUserDto> signUp({
    required String email,
    required String password,
    required String nickname,
  });
  Future<AuthUserDto> signIn({required String email, required String password});
  Future<void> signOut();
  Future<bool> isNicknameAvailable(String nickname);
  Future<void> sendPasswordResetCode(String email);
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  });
  Future<void> updatePassword(String newPassword);
}
