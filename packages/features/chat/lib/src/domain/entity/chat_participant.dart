import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_participant.freezed.dart';

/// 방 참여자 하나.
///
/// 표시 이름은 **방별 닉네임**이다. 프로필 닉네임을 쓰지 않는 것이 오픈방의
/// 질감이라(계획서 "정체성") 여기에 프로필 아바타·닉네임을 끌어오지 않는다.
/// 신고·차단은 [userId] 기준이다 — 닉네임이 방별이어도 제재는 계정에 붙는다.
@freezed
class ChatParticipant with _$ChatParticipant {
  const ChatParticipant({
    required this.userId,
    required this.nickname,
    required this.joinedAt,
    this.leftAt,
  });

  @override
  final String userId;
  @override
  final String nickname;
  @override
  final DateTime joinedAt;

  /// 값이 있으면 나간 사람이다. 메시지는 방에 남아 있으므로 이름을 붙이려면
  /// 나간 참여자도 조회 결과에 들어온다.
  @override
  final DateTime? leftAt;

  bool get hasLeft => leftAt != null;
}
