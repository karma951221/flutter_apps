import 'dart:convert';

import '../../../../core/error/failure.dart';

/// 댓글 커서. `(created_at, id)` 복합 커서를 불투명 문자열로 감싼다.
///
/// 피드와 달리 **오래된 순**으로 읽는다. 대댓글이 있는 목록에서 최신순은 대화
/// 흐름이 깨지기 때문이다. 방향이 달라도 커서의 성질은 같다 — `created_at` 이
/// 같은 항목이 여러 개일 수 있으므로 `id` tie-break 를 반드시 넣는다.
///
/// 이 형식을 아는 곳은 data 계층뿐이다. domain 과 presentation 은 문자열을
/// 해석하지 않고 그대로 되돌려준다.
class CommentCursor {
  const CommentCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  /// 정렬 기준이 되는 마지막 항목으로 다음 페이지 커서를 만든다.
  String encode() {
    final raw = '${createdAt.toUtc().toIso8601String()}$_separator$id';
    return base64Url.encode(utf8.encode(raw));
  }

  /// 문자열을 커서로 되돌린다. 첫 페이지를 뜻하는 null/빈 값은 null 을 준다.
  static CommentCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return CommentCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(message: '잘못된 댓글 커서입니다', field: 'cursor');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CommentCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'CommentCursor(createdAt: $createdAt, id: $id)';
}
