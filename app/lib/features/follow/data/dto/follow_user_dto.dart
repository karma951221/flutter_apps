import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_user_dto.freezed.dart';
part 'follow_user_dto.g.dart';

/// `user_followers` · `user_followings` 뷰 한 행의 전송 형식.
///
/// 두 뷰의 컬럼이 같아서 DTO 도 하나다. 방향은 어느 뷰를 읽었는지로 정해진다.
@freezed
@JsonSerializable()
class FollowUserDto with _$FollowUserDto {
  const FollowUserDto({
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

  factory FollowUserDto.fromJson(Map<String, dynamic> json) =>
      _$FollowUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FollowUserDtoToJson(this);
}
