import 'package:core/core.dart';

import '../entity/diary_entry.dart';
import '../entity/entry_draft.dart';
import '../entity/entry_filter.dart';
import '../entity/story.dart';

/// 일기 저장소. 규칙 위반은 `Failure.validation(field: DiaryFailure.x.name)`,
/// 없는 id 는 `Failure.notFound()`, 저장 오류는 `Failure.unknown`.
abstract interface class DiaryRepository {
  // 스토리

  /// 전체(닫힌 것 포함). 정렬은 `StoryOrder` 가 한다.
  Stream<List<Story>> watchStories();

  /// endedAt 이 있으면 닫힌 스토리로 만든다.
  Future<Result<Story>> createStory({
    required String title,
    required DateTime startedAt,
    DateTime? endedAt,
  });

  /// 이름 · 상태 · endedAt · coverMediaId 를 저장한다.
  Future<Result<Story>> updateStory(Story story);

  /// 스토리 삭제: 기록 전부 deletedAt=now 후 스토리 행 삭제. FK 때문에 기록이
  /// 지워진 스토리 id 를 가리킬 수 없으므로 **storyId 를 'daily' 로 바꾸고 원래
  /// 스토리 id 는 버린다**(복원하면 '일상'). 이미 휴지통이던 기록은 deletedAt 을
  /// 유지한다. 기본 스토리면 defaultStoryLocked.
  Future<Result<void>> deleteStory(String id);

  // 기록

  /// 휴지통 제외, occurredAt 내림차순, 같으면 createdAt 내림차순.
  Stream<List<DiaryEntry>> watchEntries(EntryFilter filter);

  /// 휴지통 기록도 돌려준다.
  Future<Result<DiaryEntry>> entry(String id);

  /// id · createdAt = updatedAt = now 를 채우고, 스토리 lastPostedAt = now.
  /// 닫힌 스토리에는 `storyClosed`.
  Future<Result<DiaryEntry>> createEntry(EntryDraft draft);

  /// updatedAt = now, createdAt 은 그대로. 휴지통 기록은 notFound(복원 전까지 읽기만). 스토리를 바꾸면 새 스토리
  /// lastPostedAt = now(닫힌 스토리로는 `storyClosed`).
  Future<Result<DiaryEntry>> updateEntry(String id, EntryDraft draft);

  /// 기록들(휴지통 제외)을 [storyId] 로 옮기고, 하나라도 옮겼으면 그 스토리
  /// lastPostedAt = now.
  Future<Result<void>> moveEntries(List<String> ids, String storyId);

  /// [from] ~ [to](양 끝 포함)에 든 [storyId] 의 기록(휴지통 제외), 최신순.
  /// 지난 기간 스토리를 만들 때 '일상' 기록을 제안하는 데 쓴다.
  Future<List<DiaryEntry>> entriesBetween(
    DateTime from,
    DateTime to, {
    required String storyId,
  });

  // 휴지통

  /// deletedAt = now. updatedAt 은 그대로. 이미 휴지통이면 처음 deletedAt 을 유지한다.
  Future<Result<void>> trashEntry(String id);

  /// deletedAt = null. updatedAt 은 그대로. 영구 삭제됐으면 notFound.
  /// 원래 스토리가 삭제됐으면 [deleteStory] 가 이미 storyId 를 'daily' 로 옮겨 두었다.
  Future<Result<DiaryEntry>> restoreEntry(String id);

  /// 휴지통 기록, deletedAt 내림차순.
  Stream<List<DiaryEntry>> watchTrash();

  /// 영구 삭제. 한 트랜잭션: entries delete(→ media · entry_tags 연쇄) + 쓰는 기록 없는 tags · places 정리
  /// + 지워진 미디어를 표지로 둔 스토리의 coverMediaId = null. 지워진 파일의 상대 경로(path · thumbPath)를 돌려준다.
  /// 휴지통에 있는 기록만 지운다(없는 id · 살아 있는 기록은 건너뛴다). 파일은 건드리지 않는다.
  Future<Result<List<String>>> purgeEntries(List<String> ids);

  /// deletedAt <= [deletedBefore] 인 휴지통 기록을 영구 삭제한다.
  Future<Result<List<String>>> purgeTrashedBefore(DateTime deletedBefore);

  /// 휴지통 비우기.
  Future<Result<List<String>>> purgeAllTrash();

  /// DB 가 아는 모든 미디어 경로(휴지통 포함). 고아 청소용.
  Future<Set<String>> allMediaPaths();
}
