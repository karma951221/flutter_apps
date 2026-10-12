import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/named_count.dart';
import '../../../domain/diary/entity/story.dart';

part 'diary_search_state.freezed.dart';

/// 검색 탭(스펙 §6.4): 글 · 스토리 · 해시태그 · 장소.
enum SearchScope { body, story, tag, place }

/// 검색 화면. 결과 목록은 [scope] 의 것만 채운다(탭을 바꾸면 비우고 다시 조회).
@freezed
class DiarySearchState with _$DiarySearchState {
  @override
  final SearchScope scope;

  /// 입력칸 그대로(바로 바뀐다).
  @override
  final String query;

  /// 지금 결과가 가리키는 검색어 — [query] 를 trim 한 값으로, 디바운스 뒤 결과가 올 때 바뀐다.
  /// 글 결과 강조에 쓴다.
  @override
  final String searched;

  /// 태그 · 장소 추천, 쓴 횟수 → 최근 사용 순.
  @override
  final List<NamedCount> suggestions;

  /// 제목이 일치하는 스토리와 기록 수, `StoryOrder` 순.
  @override
  final List<({Story story, int count})> stories;

  /// 본문이 일치하는 기록, 최신순.
  @override
  final List<DiaryEntry> bodyResults;

  /// 지금 조회의 첫 결과를 아직 받지 못했다.
  @override
  final bool loading;

  /// 조회하지 못했다. 입력이나 탭을 바꾸면 다시 시도한다.
  @override
  final bool failed;

  const DiarySearchState({
    this.scope = SearchScope.body,
    this.query = '',
    this.searched = '',
    this.suggestions = const [],
    this.stories = const [],
    this.bodyResults = const [],
    this.loading = false,
    this.failed = false,
  });
}
