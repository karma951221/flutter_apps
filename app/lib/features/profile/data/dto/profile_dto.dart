import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_dto.freezed.dart';

/// profiles 테이블 행의 전송 형식.
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

  const ProfileDto({
    required this.id,
    required this.nickname,
    this.bio,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
  });

  static ProfileDto fromJson(Map<String, dynamic> json) => ProfileDto(
    id: json['id'] as String,
    nickname: json['nickname'] as String,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: _parseDateTime(json['created_at']),
    updatedAt: _parseDateTime(json['updated_at']),
  );

  static DateTime _parseDateTime(Object? value) => switch (value) {
    DateTime dateTime => dateTime,
    String text => DateTime.parse(text),
    _ => throw FormatException('유효하지 않은 프로필 시각입니다: $value'),
  };
}
