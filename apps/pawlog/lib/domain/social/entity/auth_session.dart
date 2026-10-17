import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

/// 로그인한 사용자. [nickname] 은 `profiles` 행에서 읽는다(트레이더와 같은 계정).
///
/// 세션은 있는데 프로필을 아직 못 읽었으면(복원 직후 · 조회 실패) [nickname] 이 빈 문자열이다.
@freezed
class AuthSession with _$AuthSession {
  @override
  final String userId;
  @override
  final String nickname;

  const AuthSession({required this.userId, required this.nickname});
}
