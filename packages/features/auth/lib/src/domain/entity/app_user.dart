import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// 로그인한 사용자.
///
/// Supabase 의 User / Session 타입은 여기까지 올라오지 않는다.
/// data 계층이 이 타입으로 변환한 뒤에야 domain / presentation 으로 넘긴다.
@freezed
class AppUser with _$AppUser {
  @override
  final String id;
  @override
  final String email;
  @override
  final String nickname;
  @override
  final String? bio;
  @override
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    this.bio,
    this.avatarUrl,
  });
}
