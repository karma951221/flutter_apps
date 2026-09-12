import 'dart:convert';

import 'package:core/core.dart';

/// 탐색 목록 커서. 공개방을 `(created_at, id)` 최신순으로 읽는다.
///
/// 마지막 활동 시각으로 정렬하면 방이 오갈 때마다 순서가 바뀌어 커서가
/// 흔들린다. 개설 시각은 변하지 않으므로 페이지 경계가 안정적이다 —
/// 부분 인덱스 `chat_rooms_open_activity_idx` 도 이 정렬로 만들어 두었다.
class RoomCursor {
  const RoomCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  String encode() {
    final raw = '${createdAt.toUtc().toIso8601String()}$_separator$id';
    return base64Url.encode(utf8.encode(raw));
  }

  static RoomCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return RoomCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(
        message: '잘못된 방 커서입니다',
        field: 'cursor',
        failureCode: FailureCode.roomCursorInvalid,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RoomCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);
}
