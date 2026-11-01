import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/chat/entity/wiki_note.dart';
import '../../../../domain/diary/entity/diary_entry.dart';

part 'wiki_note_state.freezed.dart';

/// 메모 하나와, 본문 링크를 그리는 데 필요한 것을 미리 읽어 둔 상태.
@freezed
class WikiNoteState with _$WikiNoteState {
  /// 메모를 아직 받지 못했다.
  @override
  final bool loading;

  @override
  final WikiNote? note;

  /// 본문이 가리키는 메모 중 남아 있는 것. 없는 id 는 '지워진 메모'.
  @override
  final Map<int, WikiNote> linkedNotes;

  /// 본문이 가리키는 일기 중 살아 있는 것(휴지통 제외). 없는 id 는 '지워진 일기'.
  @override
  final Map<String, DiaryEntry> linkedEntries;

  /// 본문에 이 메모의 링크가 든 메모, updatedAt 최근 순.
  @override
  final List<WikiNote> backlinks;

  /// 출처 대화가 아직 남아 있다.
  @override
  final bool sourceExists;

  /// 메모가 사라졌다 — 화면이 닫힌다.
  @override
  final bool deleted;

  /// 메모를 읽지 못했다(스트림 오류).
  @override
  final bool failed;

  const WikiNoteState({
    this.loading = true,
    this.note,
    this.linkedNotes = const {},
    this.linkedEntries = const {},
    this.backlinks = const [],
    this.sourceExists = false,
    this.deleted = false,
    this.failed = false,
  });

  @override
  String toString() =>
      'WikiNoteState(loading: $loading, note: $note, '
      'linkedNotes: ${linkedNotes.length}, '
      'linkedEntries: ${linkedEntries.length}, '
      'backlinks: ${backlinks.length}, sourceExists: $sourceExists, '
      'deleted: $deleted, failed: $failed)';
}
