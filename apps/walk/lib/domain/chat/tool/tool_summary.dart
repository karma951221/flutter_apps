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

  /// list_files
  listFiles,

  /// read_file
  readFile,

  /// 벤더 서버의 웹 검색(web_search). 세션이 실행하지 않고 결과 개수도 없다.
  webSearch,
  other,
}

ChatToolKind chatToolKindOf(String name) => switch (name) {
  'search_diary' => ChatToolKind.searchDiary,
  'view_entry_photos' => ChatToolKind.viewPhotos,
  'list_diary_index' => ChatToolKind.diaryIndex,
  'daily_steps' => ChatToolKind.dailySteps,
  'wake_records' => ChatToolKind.wakeRecords,
  'read_wiki' => ChatToolKind.wiki,
  'list_files' => ChatToolKind.listFiles,
  'read_file' => ChatToolKind.readFile,
  'web_search' => ChatToolKind.webSearch,
  _ => ChatToolKind.other,
};

/// 도구 입력에서 라벨용으로 꺼낸 것만. 잘못된 날짜는 null.
/// toString 은 kind · 날짜 유무만 — 검색어(query) · 파일 이름(name)은 찍지 않는다.
@freezed
class ToolInputSummary with _$ToolInputSummary {
  @override
  final ChatToolKind kind;
  @override
  final DateTime? from;
  @override
  final DateTime? to;

  /// search_diary · web_search 의 query(앞뒤 trim, 20자 넘으면 20자 + '…').
  @override
  final String? query;

  /// read_file 의 파일 이름(path 마지막 부분, 20자 넘으면 20자 + '…').
  @override
  final String? name;

  const ToolInputSummary({
    required this.kind,
    this.from,
    this.to,
    this.query,
    this.name,
  });

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
