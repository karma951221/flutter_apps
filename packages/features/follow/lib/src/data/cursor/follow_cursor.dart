import 'dart:convert';

import 'package:core/core.dart';

/// 팔로우 목록 커서. `(created_at, id)` 복합 커서를 불투명 문자열로 감싼다.
///
/// 여기서 `id` 는 상대의 프로필 id 다 — 목록 뷰가 방향에 따라 반대쪽 컬럼을
/// `id` 로 내려주므로, 팔로워 · 팔로잉 어느 쪽이든 같은 커서를 쓴다.
///
/// 형식과 실패 처리는 [FeedCursor] 와 같다. 커서 종류마다 클래스를 두는 것은
/// 서로 다른 목록의 커서가 섞여 들어오는 것을 타입으로 막기 위해서다.
class FollowCursor {
  const FollowCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  String encode() {
    final raw = '${createdAt.toUtc().toIso8601String()}$_separator$id';
    return base64Url.encode(utf8.encode(raw));
  }

  static FollowCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return FollowCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(
        message: '잘못된 팔로우 커서입니다',
        field: 'cursor',
        failureCode: FailureCode.followCursorInvalid,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FollowCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'FollowCursor(createdAt: $createdAt, id: $id)';
}
