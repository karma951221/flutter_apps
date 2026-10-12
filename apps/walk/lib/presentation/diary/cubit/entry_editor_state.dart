import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/diary_failure.dart';
import '../../../domain/diary/entity/entry_draft.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';

part 'entry_editor_state.freezed.dart';

/// 기록 작성 · 수정 화면(스펙 §6.2).
@freezed
class EntryEditorState with _$EntryEditorState {
  /// 고치는 기록 id. null 이면 새 기록.
  @override
  final String? editingId;

  @override
  final EntryDraft draft;

  /// 새 기록이면 화면을 연 시각, 수정이면 기록의 createdAt. '되돌리기'의 기준.
  @override
  final DateTime createdAt;

  /// 스토리 시트에 고를 수 있는 열린 스토리, `StoryOrder` 순서.
  @override
  final List<Story> openStories;

  /// 닫힌 것까지 모든 스토리 — 고친 기록이 닫힌 스토리에 있어도 이름을 보인다.
  @override
  final List<Story> stories;

  /// 지금 위치를 찾는 중.
  @override
  final bool locating;

  /// 지금 위치 대신 장소 이름을 직접 입력한다(과거 시각 · 위치 없음 · 위치 뺌).
  @override
  final bool manualPlace;

  @override
  final bool saving;

  /// 고른 사진 · 영상을 압축하는 중. 그동안 저장하지 않는다.
  @override
  final bool importing;

  /// 이 화면에서 새로 가져온 임시 사본(tmp). 취소하면 지운다.
  @override
  final List<EntryMedia> newMedia;

  /// 일기 규칙 위반 · 없는 기록. 알릴 때마다 새 상태로 내보낸다.
  @override
  final DiaryFailure? error;

  /// 규칙 밖의 저장 · 읽기 오류(DB · 파일). 알릴 때마다 새 상태로 내보낸다.
  @override
  final bool failed;

  @override
  final bool saved;

  const EntryEditorState({
    this.editingId,
    required this.draft,
    required this.createdAt,
    this.openStories = const [],
    this.stories = const [],
    this.locating = false,
    this.manualPlace = false,
    this.saving = false,
    this.importing = false,
    this.newMedia = const [],
    this.error,
    this.failed = false,
    this.saved = false,
  });

  bool get isEditing => editingId != null;

  /// 기록 시각을 사용자가 바꿨는지 — '되돌리기'를 보인다. 시각은 분 단위로 고르므로
  /// 분까지만 비교한다(열린 시각 15:24:37 에 15:24 를 고르면 바꾼 것이 아니다).
  bool get timeEdited => !sameMinute(draft.occurredAt, createdAt);

  static bool sameMinute(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}
