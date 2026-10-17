import 'package:core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 인증 SDK 를 감싼 얇은 경계. [SupabaseAuthRepository] 는 이 계약만 알아
/// 가짜로 바꿔 시험할 수 있다. Supabase 예외는 그대로 던진다 — 변환은 저장소의 몫이다.
abstract interface class SupabaseAuthGateway {
  String? get currentUserId;

  /// 로그인 · 로그아웃 · 사용자 갱신 때의 사용자 id(로그아웃은 null).
  /// 구독하면 지금 상태(initialSession)를 먼저 낸다.
  Stream<String?> get userIdChanges;

  /// 로그인한 사용자 id.
  Future<String> signIn({required String email, required String password});

  /// 가입 후 로그인된 사용자 id. [nickname] 은 user metadata 로 넘긴다.
  Future<String> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  Future<void> signOut();

  /// `profiles.nickname`. 행이 없으면 null.
  Future<String?> fetchNickname(String userId);

  /// 대소문자를 무시하고 같은 닉네임이 이미 있는지(`profiles_nickname_lower_idx` 기준).
  Future<bool> isNicknameTaken(String nickname);
}

class SupabaseClientAuthGateway implements SupabaseAuthGateway {
  SupabaseClientAuthGateway(this._client);

  final SupabaseClient _client;

  /// 사용자 자체가 바뀌는 사건만. 토큰 갱신(한 시간마다) · 비밀번호 복구(로그인 아님) ·
  /// MFA 는 프로필을 다시 읽을 일이 아니다.
  static const _userEvents = {
    AuthChangeEvent.initialSession,
    AuthChangeEvent.signedIn,
    AuthChangeEvent.signedOut,
    AuthChangeEvent.userUpdated,
  };

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> get userIdChanges => _client.auth.onAuthStateChange
      .where((state) => _userEvents.contains(state.event))
      .map((state) => state.session?.user.id);

  @override
  Future<String> signIn({
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
    return user.id;
  }

  @override
  Future<String> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nickname': nickname.trim()},
    );
    // 이메일 확인이 켜진 프로젝트면 사용자는 생기지만 세션이 없다 — 로그인된 게 아니다.
    // 로컬(`supabase/config.toml` 의 `enable_confirmations = false`)은 바로 세션을 준다.
    final user = response.user;
    if (user == null || response.session == null) {
      throw const Failure.auth(
        message: '가입에 실패했습니다',
        code: 'no_session',
        failureCode: FailureCode.signUpFailed,
      );
    }
    return user.id;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<String?> fetchNickname(String userId) async {
    final row = await _client
        .from('profiles')
        .select('nickname')
        .eq('id', userId)
        .maybeSingle();
    return row?['nickname'] as String?;
  }

  @override
  Future<bool> isNicknameTaken(String nickname) async {
    final candidate = nickname.trim();
    // `ilike` 로 좁히고 최종 판정은 Dart 가 한다 — 이유는 core [NicknameMatch].
    final rows = await _client
        .from('profiles')
        .select('nickname')
        .ilike('nickname', NicknameMatch.escapeLikePattern(candidate))
        .limit(NicknameMatch.candidateLimit);
    return rows.any(
      (row) =>
          NicknameMatch.isSameNickname(row['nickname'] as String, candidate),
    );
  }
}
