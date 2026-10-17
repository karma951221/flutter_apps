import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

import '../../domain/social/entity/auth_session.dart';
import '../../domain/social/repository/auth_repository.dart';
import 'supabase_auth_gateway.dart';

/// [AuthRepository] 의 Supabase 구현. 오류는 core `RepositoryErrorHandler` 로 바꾼다 —
/// 틀린 자격은 [FailureCode.invalidCredentials] 가 된다.
///
/// 닉네임 중복은 가입 전에 `profiles` 를 먼저 본다. 트리거가 유일 위반으로 실패하면
/// GoTrue 는 정확히 같은 닉네임(`profiles_nickname_key`)일 때만 원인을 돌려주고,
/// 대소문자만 다른 경우(`profiles_nickname_lower_idx`)는 "Database error saving new
/// user" 로 뭉갠다(로컬 확인 2026-10-17). 앞의 경우는 `SupabaseErrorMapper` 가
/// [FailureCode.nicknameTaken] 으로 바꾸므로 사전 확인과 동시 가입 경합 모두 덮인다.
///
/// 등록은 `RegisterModule` 이 Supabase 초기화 결과를 보고 한다.
class SupabaseAuthRepository
    with RepositoryErrorHandler
    implements AuthRepository {
  SupabaseAuthRepository(this._gateway);

  final SupabaseAuthGateway _gateway;

  /// 마지막으로 프로필까지 읽은 세션.
  AuthSession? _session;

  @override
  Stream<AuthSession?> get sessions =>
      _gateway.userIdChanges.asyncMap(_resolve).distinct();

  @override
  AuthSession? get current {
    final userId = _gateway.currentUserId;
    if (userId == null) return null;
    final session = _session;
    return session?.userId == userId
        ? session
        : AuthSession(userId: userId, nickname: '');
  }

  @override
  Future<Result<void>> signIn(String email, String password) => guard(() async {
    final userId = await _gateway.signIn(email: email, password: password);
    await _resolve(userId);
  });

  @override
  Future<Result<void>> signUp(String email, String password, String nickname) =>
      guard(() async {
        if (await _isNicknameTaken(nickname)) {
          throw const Failure.validation(
            message: '이미 사용 중인 닉네임입니다',
            field: 'nickname',
            failureCode: FailureCode.nicknameTaken,
          );
        }
        final userId = await _gateway.signUp(
          email: email,
          password: password,
          nickname: nickname,
        );
        await _resolve(userId);
      });

  @override
  Future<Result<void>> signOut() => guard(() async {
    await _gateway.signOut();
    _session = null;
  });

  Future<AuthSession?> _resolve(String? userId) async {
    if (userId == null) return _session = null;
    return _session = AuthSession(
      userId: userId,
      nickname: await _nicknameOf(userId),
    );
  }

  /// 사전 확인이 실패하면 가입을 그대로 시도한다 — 최종 판정은 DB 유일 인덱스다.
  Future<bool> _isNicknameTaken(String nickname) async {
    try {
      return await _gateway.isNicknameTaken(nickname);
    } catch (error) {
      debugPrint('pawlog nickname check failed: $error');
      return false;
    }
  }

  /// 프로필 조회가 실패해도 로그인 자체를 막지 않는다(feature_auth 와 같은 판단).
  Future<String> _nicknameOf(String userId) async {
    try {
      return await _gateway.fetchNickname(userId) ?? '';
    } catch (error) {
      debugPrint('pawlog profile load failed: $error');
      return '';
    }
  }
}
