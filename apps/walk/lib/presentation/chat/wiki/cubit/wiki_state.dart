import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/chat/chat_history_settings.dart';
import '../../../../domain/chat/entity/wiki_note.dart';

part 'wiki_state.freezed.dart';

/// 위키 메모 목록과 색인에 실린 메모.
@freezed
class WikiState with _$WikiState {
  /// 첫 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// updatedAt 최근 순.
  @override
  final List<WikiNote> notes;

  /// 지금 색인 크기로 색인에 실리는 메모 id(buildWikiIndex).
  @override
  final Set<int> indexedIds;

  @override
  final WikiIndexSize size;

  /// 목록을 읽지 못했다(스트림 오류).
  @override
  final bool failed;

  const WikiState({
    this.loading = true,
    this.notes = const [],
    this.indexedIds = const {},
    this.size = WikiIndexSize.fallback,
    this.failed = false,
  });

  /// 색인에 안 실린 메모 수.
  int get notIndexed => notes.length - indexedIds.length;

  @override
  String toString() =>
      'WikiState(loading: $loading, notes: ${notes.length}, '
      'indexed: ${indexedIds.length}, size: $size, failed: $failed)';
}
