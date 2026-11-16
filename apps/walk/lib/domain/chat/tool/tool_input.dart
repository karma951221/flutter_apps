import 'dart:convert';

import 'tool_result.dart';
import 'tool_summary.dart';

/// 기록 도구들이 함께 쓰는 입력 · 출력 도우미.

final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// `YYYY-MM-DD`(앞뒤 공백 허용) → 로컬 자정. 글이 아니거나 없는 날짜면 null.
DateTime? parseToolDate(Object? v) {
  if (v is! String) return null;
  final m = _datePattern.firstMatch(v.trim());
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final date = DateTime(y, mo, d);
  return date.year == y && date.month == mo && date.day == d ? date : null;
}

/// 양 끝 포함 날짜 범위. [from] · [to] 는 로컬 자정.
class ToolRange {
  const ToolRange(this.from, this.to, this.clamped);

  final DateTime from;
  final DateTime to;

  /// 최대 일수를 넘어 [to] 기준으로 잘랐는지.
  final bool clamped;

  /// [to] 날의 마지막 순간.
  DateTime get end => DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

  /// 잘렸으면 `{"clamped": true}`, 아니면 빈 맵.
  Map<String, Object?> get clampJson => clamped ? {'clamped': true} : {};
}

/// 입력의 `from` · `to`. 틀리거나 순서가 거꾸로면 null. [maxDays] 를 넘으면 [to] 기준으로 자른다.
ToolRange? toolRange(Map<String, Object?> input, {required int maxDays}) {
  var from = parseToolDate(input['from']);
  final to = parseToolDate(input['to']);
  if (from == null || to == null || from.isAfter(to)) return null;
  final days =
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays +
      1;
  final clamped = days > maxDays;
  if (clamped) from = DateTime(to.year, to.month, to.day - (maxDays - 1));
  return ToolRange(from, to, clamped);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `YYYY-MM-DD`
String toolDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// `HH:mm`
String toolTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// `{"error": code}` 오류 결과.
ToolResult toolError(String code, ChatToolKind kind) => ToolResult(
  json: jsonEncode({'error': code}),
  isError: true,
  summary: ToolSummary(kind: kind, count: 0, isError: true),
);
