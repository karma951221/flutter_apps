import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_participant_dto.freezed.dart';
part 'chat_participant_dto.g.dart';

/// `chat_participants` 한 행.
@freezed
@JsonSerializable()
class ChatParticipantDto with _$ChatParticipantDto {
  const ChatParticipantDto({
    required this.userId,
    required this.nickname,
    required this.joinedAt,
    this.leftAt,
  });

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String nickname;
  @override
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @override
  @JsonKey(name: 'left_at')
  final DateTime? leftAt;

  factory ChatParticipantDto.fromJson(Map<String, dynamic> json) =>
      _$ChatParticipantDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatParticipantDtoToJson(this);
}
