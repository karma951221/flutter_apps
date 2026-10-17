import 'dart:convert';

import 'package:core/core.dart';

/// 모두의 산책 커서 — `(created_at desc, id desc)` 의 마지막 글.
///
/// 바깥 계층에는 [encode] 한 불투명 문자열(`CursorPage.nextCursor`)로만 나간다.
/// 시각은 마이크로초까지 UTC 로 보존한다 — Postgres timestamptz 가 마이크로초라
/// 밀리초로 자르면 같은 밀리초 안의 글이 건너뛰어지거나 겹친다.
class WalkPostCursor {
  WalkPostCursor({required DateTime createdAt, required this.id})
    : createdAt = createdAt.toUtc();

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  String encode() => base64Url.encode(
    utf8.encode('${createdAt.toIso8601String()}$_separator$id'),
  );

  static WalkPostCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return WalkPostCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(
        message: '잘못된 모두의 산책 커서입니다',
        field: 'cursor',
        failureCode: FailureCode.feedCursorInvalid,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is WalkPostCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'WalkPostCursor($createdAt, $id)';
}
