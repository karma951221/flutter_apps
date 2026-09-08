import 'dart:convert';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_code.dart';

/// 지난 판 목록 커서. `(created_at, id)` 복합 커서를 불투명 문자열로 감싼다.
///
/// 형식과 실패 처리는 [FollowCursor] 와 같다. 깨진 값에 전용 코드를 새로
/// 만들지 않고 공용 [FailureCode.invalidData] 를 쓴다(task 5 brief) — 커서
/// 종류가 늘 때마다 실패 코드까지 늘리지 않기 위해서다.
class TradeCursor {
  const TradeCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;

  static const _separator = '|';

  String encode() {
    final raw = '${createdAt.toUtc().toIso8601String()}$_separator$id';
    return base64Url.encode(utf8.encode(raw));
  }

  static TradeCursor? decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final raw = utf8.decode(base64Url.decode(encoded));
      final parts = raw.split(_separator);
      if (parts.length != 2 || parts[1].isEmpty) {
        throw const FormatException('커서 형식이 아닙니다');
      }
      return TradeCursor(createdAt: DateTime.parse(parts[0]), id: parts[1]);
    } on FormatException {
      throw const Failure.validation(
        message: '잘못된 판 커서입니다',
        field: 'cursor',
        failureCode: FailureCode.invalidData,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TradeCursor && other.createdAt == createdAt && other.id == id;

  @override
  int get hashCode => Object.hash(createdAt, id);

  @override
  String toString() => 'TradeCursor(createdAt: $createdAt, id: $id)';
}
