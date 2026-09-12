import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/app_user.dart';

part 'auth_state.freezed.dart';

/// 앱 전역 인증 상태.
///
/// unknown 은 "아직 판단 못 함"이다. 저장된 세션을 읽는 동안의 상태로,
/// 이게 없으면 앱 시작 시 로그인 화면이 잠깐 번쩍였다가 홈으로 넘어간다.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;
  const factory AuthState.authenticated(AppUser user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
}
