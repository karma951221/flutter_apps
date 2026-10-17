import 'package:core/core.dart';

import '../../domain/social/entity/auth_session.dart';
import '../../domain/social/repository/auth_repository.dart';

/// Supabase 초기화가 실패했을 때의 [AuthRepository]. 늘 로그아웃 상태이고 로그인 · 가입은
/// 네트워크 실패다 — 화면은 앱을 죽이지 않고 오류 안내를 보인다.
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  static const _failure = Failure.network(
    failureCode: FailureCode.networkUnavailable,
  );

  @override
  Stream<AuthSession?> get sessions => Stream.value(null);

  @override
  AuthSession? get current => null;

  @override
  Future<Result<void>> signIn(String email, String password) async =>
      const Err(_failure);

  @override
  Future<Result<void>> signUp(
    String email,
    String password,
    String nickname,
  ) async => const Err(_failure);

  /// 로그인한 적이 없으니 할 일이 없다.
  @override
  Future<Result<void>> signOut() async => const Ok(null);
}
