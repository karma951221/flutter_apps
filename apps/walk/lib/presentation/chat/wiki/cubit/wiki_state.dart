import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/chat/chat_history_settings.dart';
import '../../../../domain/chat/entity/wiki_note.dart';

part 'wiki_state.freezed.dart';

/// 위키 화면 — 지금 보이는 쪽(검색 결과일 수 있다)과 색인 표시.
@freezed
class WikiState with _$WikiState {
  /// 첫 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// 지금까지 읽은 쪽들. updatedAt 최근 순. [searched] 가 있으면 그 결과만.
  @override
  final List<WikiNote> notes;

  /// 뒤에 더 읽을 메모가 있다.
  @override
  final bool hasMore;

  /// 다음 쪽을 읽는 중.
  @override
  final bool loadingMore;

  /// 입력칸 글자(디바운스 전).
  @override
  final String query;

  /// [notes] 를 찾은 검색어(trim). 비면 전체 목록.
  @override
  final String searched;

  /// 전체 메모 수(검색과 무관).
  @override
  final int total;

  /// 지금 색인 크기로 색인에 실리는 메모 id(buildWikiIndex).
  @override
  final Set<int> indexedIds;

  /// 지금 색인의 글자 수(색인 크기 시트에 보인다).
  @override
  final int indexChars;

  @override
  final WikiIndexSize size;

  /// 목록을 읽지 못했다(스트림 오류).
  @override
  final bool failed;

  const WikiState({
    this.loading = true,
    this.notes = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.query = '',
    this.searched = '',
    this.total = 0,
    this.indexedIds = const {},
    this.indexChars = 0,
    this.size = WikiIndexSize.fallback,
    this.failed = false,
  });

  /// 색인에 안 실린 메모 수.
  int get notIndexed => total - indexedIds.length;

  /// 지금 입력으로 찾았는데 맞는 메모가 없다(디바운스 중이면 false).
  bool get noResults =>
      searched.isNotEmpty && searched == query.trim() && notes.isEmpty;

  @override
  String toString() =>
      'WikiState(loading: $loading, notes: ${notes.length}, '
      'hasMore: $hasMore, total: $total, indexed: ${indexedIds.length}, '
      'searching: ${searched.isNotEmpty}, size: $size, failed: $failed)';
}
