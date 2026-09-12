import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_user_dto.freezed.dart';
part 'blocked_user_dto.g.dart';

/// `blocked_users` 뷰 한 행의 전송 형식.
@freezed
@JsonSerializable()
class BlockedUserDto with _$BlockedUserDto {
  const BlockedUserDto({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String nickname;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  factory BlockedUserDto.fromJson(Map<String, dynamic> json) =>
      _$BlockedUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedUserDtoToJson(this);
}
