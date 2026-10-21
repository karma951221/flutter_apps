import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';

part 'filtered_entries_state.freezed.dart';

/// 태그 · 장소 모아보기(스펙 §6.4) — 스토리를 넘나든다.
@freezed
class FilteredEntriesState with _$FilteredEntriesState {
  /// 필터에 맞는 기록(휴지통 제외), 최신순.
  @override
  final List<DiaryEntry> entries;

  /// 기록마다 붙일 스토리 이름표용(닫힌 것 포함).
  @override
  final List<Story> stories;

  /// 첫 기록 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// 기록 목록을 읽지 못했다.
  @override
  final bool failed;

  const FilteredEntriesState({
    this.entries = const [],
    this.stories = const [],
    this.loading = true,
    this.failed = false,
  });
}
