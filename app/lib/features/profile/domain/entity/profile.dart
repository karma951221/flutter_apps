import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// 앱에서 표시하는 공개 프로필.
///
/// Supabase의 응답 형식은 data 계층의 DTO에서만 다루고, 이 타입은
/// presentation과 다른 feature가 안전하게 공유하는 계약이다.
@freezed
class Profile with _$Profile {
  @override
  final String id;
  @override
  final String nickname;
  @override
  final String? bio;
  @override
  final String? avatarUrl;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.nickname,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });
}
