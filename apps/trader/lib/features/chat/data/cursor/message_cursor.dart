import 'dart:convert';

import 'package:core/core.dart';

/// 메시지 커서. `(created_at, id)` 복합 커서를 불투명 문자열로 감싼다.
///
/// 피드와 같은 **최신순**이다. 방에 들어가면 최근 것부터 읽고, 위로 스크롤하면
/// 더 오래된 페이지를 잇는다. 화면은 받은 목록을 뒤집어 그린다.
///
/// 이 형식을 아는 곳은 data 계층뿐이다 (아키텍처 §3-1).
class MessageCursor {
  const MessageCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  String encode() {
    final raw = '${createdAt.toUtc().toIso8601String()}$_separator$id';
    return base64Url.encode(utf8.encode(raw));
  }

  static MessageCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return MessageCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(
        message: '잘못된 메시지 커서입니다',
        field: 'cursor',
        failureCode: FailureCode.messageCursorInvalid,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MessageCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'MessageCursor(createdAt: $createdAt, id: $id)';
}
