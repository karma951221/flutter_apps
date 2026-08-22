import 'dart:convert';

import '../../../../core/error/failure.dart';

/// 피드 커서. `(created_at, id)` 복합 커서를 불투명 문자열로 감싼다.
///
/// domain 과 presentation 은 이 문자열을 해석하지 않고 그대로 되돌려준다.
/// 커서 표현을 바꿔도 data 계층 밖은 영향을 받지 않는다.
///
/// `OFFSET` 대신 커서를 쓰는 이유: 스크롤 중 새 글이 올라오면 offset 이 밀려
/// 같은 게시물이 두 번 나오거나 건너뛰어진다.
class FeedCursor {
  const FeedCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  /// 정렬 기준이 되는 마지막 항목으로 다음 페이지 커서를 만든다.
  String encode() {
    final raw = '${createdAt.toUtc().toIso8601String()}$_separator$id';
    return base64Url.encode(utf8.encode(raw));
  }

  /// 문자열을 커서로 되돌린다. 첫 페이지를 뜻하는 null/빈 값은 null 을 준다.
  static FeedCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return FeedCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(
        message: '잘못된 피드 커서입니다',
        field: 'cursor',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is FeedCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'FeedCursor(createdAt: $createdAt, id: $id)';
}
