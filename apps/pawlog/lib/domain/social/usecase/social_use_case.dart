import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/auth_session.dart';
import '../repository/auth_repository.dart';

/// 모두의 산책(W5 social) facade — 로그인 · 공유 · 좋아요를 [WalkUseCase] 와 나눠 둔다.
abstract interface class SocialUseCase {
  Stream<AuthSession?> get sessions;

  AuthSession? get currentSession;

  Future<Result<void>> signIn(String email, String password);

  Future<Result<void>> signUp(String email, String password, String nickname);

  Future<Result<void>> signOut();
}

@LazySingleton(as: SocialUseCase)
class DefaultSocialUseCase implements SocialUseCase {
  DefaultSocialUseCase(this._auth);

  final AuthRepository _auth;

  @override
  Stream<AuthSession?> get sessions => _auth.sessions;

  @override
  AuthSession? get currentSession => _auth.current;

  @override
  Future<Result<void>> signIn(String email, String password) =>
      _auth.signIn(email.trim(), password);

  @override
  Future<Result<void>> signUp(String email, String password, String nickname) =>
      _auth.signUp(email.trim(), password, nickname.trim());

  @override
  Future<Result<void>> signOut() => _auth.signOut();
}
