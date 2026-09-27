import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:core/core.dart';
import '../dto/auth_user_dto.dart';
import 'auth_data_source.dart';

@LazySingleton(as: AuthDataSource)
class SupabaseAuthDataSource implements AuthDataSource {
  SupabaseAuthDataSource(this._client);

  final supabase.SupabaseClient _client;

  static const _profileColumns = 'id, nickname, bio, avatar_url';

  @override
  Stream<AuthUserDto?> authStateChanges() {
    late final StreamController<AuthUserDto?> controller;
    StreamSubscription<supabase.AuthState>? subscription;

    Future<void> handle(supabase.AuthState event) async {
      if (controller.isClosed) return;
      debugPrint(
        '[auth] event=${event.event} session=${event.session != null}',
      );

      // passwordRecovery 는 "코드 검증 성공"일 뿐 로그인이 아니다.
      if (event.event == supabase.AuthChangeEvent.passwordRecovery) return;

      final user = event.session?.user;
      if (user == null) {
        controller.add(null);
        return;
      }

      try {
        controller.add(await _loadUser(user));
      } catch (error) {
        // 프로필 조회 실패가 로그인 자체를 막아서는 안 된다.
        debugPrint('[auth] 프로필 조회 실패, 최소 정보로 진행: $error');
        controller.add(
          AuthUserDto(id: user.id, email: user.email ?? '', nickname: ''),
        );
      }
    }

    controller = StreamController<AuthUserDto?>(
      onListen: () async {
        subscription = _client.auth.onAuthStateChange.listen(
          handle,
          onError: controller.addError,
        );
        // 구독 이전에 이미 복원된 세션이 있으면 그것도 흘려준다.
        if (!controller.isClosed) controller.add(await currentUser());
      },
      onCancel: () async => subscription?.cancel(),
    );

    return controller.stream;
  }

  @override
  Future<AuthUserDto?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadUser(user);
  }

  @override
  Future<AuthUserDto> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nickname': nickname.trim()},
    );
    final user = response.user;
    if (user == null) {
      throw const Failure.server(
        message: '가입에 실패했습니다',
        code: 'empty_user',
        failureCode: FailureCode.signUpFailed,
      );
    }
    return _loadUser(user);
  }

  @override
  Future<AuthUserDto> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const Failure.auth(
        message: '로그인에 실패했습니다',
        code: 'empty_user',
        failureCode: FailureCode.signInFailed,
      );
    }
    return _loadUser(user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<bool> isNicknameAvailable(String nickname) async {
    final candidate = nickname.trim();
    // `ilike` 로 좁히고 최종 판정은 Dart 가 한다 — 이유는 [NicknameMatch].
    final rows = await _client
        .from('profiles')
        .select('nickname')
        .ilike('nickname', NicknameMatch.escapeLikePattern(candidate))
        .limit(NicknameMatch.candidateLimit);
    return !rows.any(
      (row) =>
          NicknameMatch.isSameNickname(row['nickname'] as String, candidate),
    );
  }

  @override
  Future<void> sendPasswordResetCode(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  @override
  Future<void> verifyPasswordResetCode({
    required String email,
    required String code,
  }) => _client.auth.verifyOTP(
    type: supabase.OtpType.recovery,
    email: email.trim(),
    token: code.trim(),
  );

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      supabase.UserAttributes(password: newPassword),
    );
    // 재설정용 임시 세션을 그대로 두고 홈으로 보내지 않는다.
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    // 서버가 계정과 데이터를 한 트랜잭션에 지운다 (apps/trader/docs/schema.md 참고).
    await _client.rpc<void>('delete_account');
    // 사용자 행이 이미 없으므로 서버 로그아웃은 실패한다. 로컬 세션만 지운다 —
    // 이 호출이 auth 상태 스트림을 깨워 라우터가 로그인 화면으로 보낸다.
    await _client.auth.signOut(scope: supabase.SignOutScope.local);
  }

  Future<AuthUserDto> _loadUser(supabase.User user) async {
    final row = await _client
        .from('profiles')
        .select(_profileColumns)
        .eq('id', user.id)
        .maybeSingle();

    return AuthUserDto(
      id: user.id,
      email: user.email ?? '',
      nickname: row?['nickname'] as String? ?? '',
      bio: row?['bio'] as String?,
      avatarUrl: row?['avatar_url'] as String?,
    );
  }
}
