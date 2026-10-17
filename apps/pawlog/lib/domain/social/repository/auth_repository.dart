import 'package:core/core.dart';

import '../entity/auth_session.dart';

/// pawlog 의 로그인 — 공유 · 좋아요를 할 때만 필요하다(plan 결정 6).
abstract interface class AuthRepository {
  /// 로그인 상태 변화. 구독하면 지금 상태를 먼저 한 번 낸다. 로그아웃은 null.
  Stream<AuthSession?> get sessions;

  /// 지금 로그인한 사용자. 동기로 읽는다 — 닉네임을 아직 못 읽었으면 빈 문자열이다.
  AuthSession? get current;

  Future<Result<void>> signIn(String email, String password);

  /// [nickname] 은 user metadata 로 넘기고 DB 트리거가 프로필을 만든다.
  /// 겹치면 [FailureCode.nicknameTaken].
  Future<Result<void>> signUp(String email, String password, String nickname);

  Future<Result<void>> signOut();
}
