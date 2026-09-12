import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_dto.freezed.dart';

/// `profile_details` 뷰(또는 `profiles` 테이블) 행의 전송 형식.
///
/// 팔로우 수·관계 네 컬럼은 뷰에만 있다. 갱신 응답처럼 테이블에서 직접 온
/// 행에는 없으므로 기본값으로 떨어진다 — 그 자리의 화면은 수를 그리지 않는다.
///
/// Supabase 응답은 이 타입에서만 해석하고, domain에는 노출하지 않는다.
@freezed
class ProfileDto with _$ProfileDto {
  @override
  final String id;
  @override
  final String nickname;
  @override
  final String? bio;
  @JsonKey(name: 'avatar_url')
  @override
  final String? avatarUrl;
  @JsonKey(name: 'created_at')
  @override
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  @override
  final DateTime updatedAt;
  @JsonKey(name: 'follower_count')
  @override
  final int followerCount;
  @JsonKey(name: 'following_count')
  @override
  final int followingCount;
  @JsonKey(name: 'is_following')
  @override
  final bool isFollowing;
  @JsonKey(name: 'is_followed_by')
  @override
  final bool isFollowedBy;

  const ProfileDto({
    required this.id,
    required this.nickname,
    this.bio,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
    @JsonKey(name: 'follower_count') this.followerCount = 0,
    @JsonKey(name: 'following_count') this.followingCount = 0,
    @JsonKey(name: 'is_following') this.isFollowing = false,
    @JsonKey(name: 'is_followed_by') this.isFollowedBy = false,
  });

  static ProfileDto fromJson(Map<String, dynamic> json) => ProfileDto(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: _parseDateTime(json['created_at']),
    updatedAt: _parseDateTime(json['updated_at']),
    followerCount: json['follower_count'] as int? ?? 0,
    followingCount: json['following_count'] as int? ?? 0,
    isFollowing: json['is_following'] as bool? ?? false,
    isFollowedBy: json['is_followed_by'] as bool? ?? false,
  );

  static DateTime _parseDateTime(Object? value) => switch (value) {
    DateTime dateTime => dateTime,
    String text => DateTime.parse(text),
    _ => throw FormatException('유효하지 않은 프로필 시각입니다: $value'),
  };
}
