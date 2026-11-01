import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_summary.freezed.dart';

/// 진행 줄 라벨에 쓰는 도구 종류. 알 수 없는 이름은 other.
enum ChatToolKind {
  searchDiary,
  viewPhotos,
  diaryIndex,
  dailySteps,
  wakeRecords,

  /// read_wiki
  wiki,
  other,
}

ChatToolKind chatToolKindOf(String name) => switch (name) {
  'search_diary' => ChatToolKind.searchDiary,
  'view_entry_photos' => ChatToolKind.viewPhotos,
  'list_diary_index' => ChatToolKind.diaryIndex,
  'daily_steps' => ChatToolKind.dailySteps,
  'wake_records' => ChatToolKind.wakeRecords,
  'read_wiki' => ChatToolKind.wiki,
  _ => ChatToolKind.other,
};

/// 도구 입력에서 라벨용으로 꺼낸 것만. 잘못된 날짜는 null.
/// toString 은 kind · 날짜 유무만 — 검색어(query)는 찍지 않는다.
@freezed
class ToolInputSummary with _$ToolInputSummary {
  @override
  final ChatToolKind kind;
  @override
  final DateTime? from;
  @override
  final DateTime? to;

  /// search_diary 의 query(앞뒤 trim, 20자 넘으면 20자 + '…').
  @override
  final String? query;

  const ToolInputSummary({required this.kind, this.from, this.to, this.query});

  @override
  String toString() => 'ToolInputSummary($kind, range: ${from != null})';
}

/// 결과 개수(Q6 — 개수만). 오류 결과면 count 0 · isError.
@freezed
class ToolSummary with _$ToolSummary {
  @override
  final ChatToolKind kind;
  @override
  final int count;
  @override
  final bool isError;

  const ToolSummary({
    required this.kind,
    required this.count,
    this.isError = false,
  });
}
