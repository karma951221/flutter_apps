import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/chat/usecase/chat_session.dart';
import '../../../../domain/diary/entity/diary_entry.dart';

part 'wiki_distill_state.freezed.dart';

enum CandidateStatus { pending, saved, discarded }

/// 후보 시트의 카드 하나. `toString` 은 [WikiCandidate] · [WikiNote] 의 것이라 글을 담지 않는다.
@freezed
class CandidateItem with _$CandidateItem {
  @override
  final WikiCandidate candidate;

  /// update 후보일 때 지금 메모. 그새 지워졌으면 null.
  @override
  final WikiNote? current;

  @override
  final CandidateStatus status;

  const CandidateItem({
    required this.candidate,
    this.current,
    this.status = CandidateStatus.pending,
  });

  @override
  String toString() =>
      'CandidateItem(candidate: $candidate, current: $current, '
      'status: ${status.name})';
}

/// [위키로 정리] 후보 시트. `toString` 은 글 대신 개수만 담는다.
@freezed
sealed class WikiDistillState with _$WikiDistillState {
  const WikiDistillState._();

  const factory WikiDistillState.loading() = WikiDistillLoading;

  /// 빈 목록이면 "남길 내용이 없어요". [notes] 는 지금 위키(링크 칩 제목 · update 의 지금 메모),
  /// [entries] 는 대화의 근거 일기 중 살아 있는 것(링크 칩), [citedEntryIds] 는 그 근거 id
  /// 전부(나온 순서, 중복 없이 — [고쳐서 저장]의 일기 고르기 위쪽).
  const factory WikiDistillState.ready(
    List<CandidateItem> items, {
    @Default({}) Map<int, WikiNote> notes,
    @Default({}) Map<String, DiaryEntry> entries,
    @Default([]) List<String> citedEntryIds,
  }) = WikiDistillReady;

  const factory WikiDistillState.failed(ChatFailure failure) =
      WikiDistillFailedState;

  const factory WikiDistillState.unparsable() = WikiDistillUnparsableState;

  @override
  String toString() => switch (this) {
    WikiDistillLoading() => 'WikiDistillState.loading()',
    WikiDistillReady(:final items, :final notes, :final entries) =>
      'WikiDistillState.ready(items: $items, notes: ${notes.length}, '
          'entries: ${entries.length})',
    WikiDistillFailedState(:final failure) =>
      'WikiDistillState.failed(${failure.name})',
    WikiDistillUnparsableState() => 'WikiDistillState.unparsable()',
  };
}
