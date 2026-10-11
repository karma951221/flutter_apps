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

  // 기록

  /// 휴지통 제외, occurredAt 내림차순, 같으면 createdAt 내림차순.
  Stream<List<DiaryEntry>> watchEntries(EntryFilter filter);

  /// 휴지통 기록도 돌려준다.
  Future<Result<DiaryEntry>> entry(String id);

  /// id · createdAt = updatedAt = now 를 채우고, 스토리 lastPostedAt = now.
  /// 닫힌 스토리에는 `storyClosed`.
  Future<Result<DiaryEntry>> createEntry(EntryDraft draft);

  /// updatedAt = now, createdAt 은 그대로. 스토리를 바꾸면 새 스토리
  /// lastPostedAt = now(닫힌 스토리로는 `storyClosed`).
  Future<Result<DiaryEntry>> updateEntry(String id, EntryDraft draft);

  /// 기록들을 [storyId] 로 옮기고 그 스토리 lastPostedAt = now.
  Future<Result<void>> moveEntries(List<String> ids, String storyId);

  /// [from] ~ [to](양 끝 포함)에 든 [storyId] 의 기록(휴지통 제외), 최신순.
  /// 지난 기간 스토리를 만들 때 '일상' 기록을 제안하는 데 쓴다.
  Future<List<DiaryEntry>> entriesBetween(
    DateTime from,
    DateTime to, {
    required String storyId,
  });
}
