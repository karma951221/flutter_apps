import 'package:freezed_annotation/freezed_annotation.dart';

part 'blocked_user.freezed.dart';

/// 내가 차단한 사용자 한 명. 차단 목록 화면이 그린다.
@freezed
class BlockedUser with _$BlockedUser {
  @override
  final String id;
  @override
  final String nickname;
  @override
  final String? avatarUrl;
  @override
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.blockedAt,
  });
}
