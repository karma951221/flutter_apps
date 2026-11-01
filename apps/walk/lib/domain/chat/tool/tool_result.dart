import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'tool_summary.dart';

part 'tool_result.freezed.dart';

/// tool_result 에 붙는 이미지 한 장.
@freezed
class ToolImage with _$ToolImage {
  @override
  final String mediaType;
  @override
  final Uint8List bytes;

  const ToolImage({required this.mediaType, required this.bytes});
}

/// 도구 한 번의 결과.
@freezed
class ToolResult with _$ToolResult {
  /// tool_result 의 text 내용.
  @override
  final String json;

  /// tool_result 에 이미지 블록으로 붙는다.
  @override
  final List<ToolImage> images;

  /// 이 결과에 나온 일기 id(인용 칩 후보).
  @override
  final List<String> entryIds;
  @override
  final bool isError;

  /// 진행 줄에 쓰는 결과 개수. 없으면 null.
  @override
  final ToolSummary? summary;

  const ToolResult({
    required this.json,
    this.images = const [],
    this.entryIds = const [],
    this.isError = false,
    this.summary,
  });

  /// json(메모 본문 · 일기 글)과 entryIds 는 찍지 않는다.
  @override
  String toString() =>
      'ToolResult(jsonLength: ${json.length}, images: ${images.length}, '
      'entryIds: ${entryIds.length}, isError: $isError, '
      'kind: ${summary?.kind.name})';
}
