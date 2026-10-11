import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../diary_failure.dart';

part 'story.freezed.dart';

enum StoryStatus { open, closed }

/// 기록을 묶는 이야기(여행 · 시기). 기본 스토리 [dailyId] 는 닫을 수 없다.
@freezed
class Story with _$Story {
  static const dailyId = 'daily';

  @override
  final String id;

  /// 빈 문자열이면 표시할 때 l10n 기본 제목을 쓴다.
  @override
  final String title;

  @override
  final StoryStatus status;

  @override
  final DateTime startedAt;

  @override
  final DateTime? endedAt;

  @override
  final String? coverMediaId;

  @override
  final DateTime? lastPostedAt;

  @override
  final DateTime createdAt;

  const Story({
    required this.id,
    required this.title,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.coverMediaId,
    this.lastPostedAt,
    required this.createdAt,
  });

  bool get isDefault => id == dailyId;

  bool get isOpen => status == StoryStatus.open;

  /// [at] 이 이 스토리의 기간(양 끝 포함)에 드는지. endedAt 이 없으면 startedAt 이후 전부.
  bool covers(DateTime at) {
    if (at.isBefore(startedAt)) return false;
    final end = endedAt;
    return end == null || !at.isAfter(end);
  }

  /// 기본 스토리 · [at] < startedAt 은 거절한다.
  Result<Story> close(DateTime at) {
    if (isDefault) return Err(DiaryFailure.defaultStoryLocked.toFailure());
    if (at.isBefore(startedAt)) {
      return Err(DiaryFailure.endBeforeStart.toFailure());
    }
    return Ok(
      Story(
        id: id,
        title: title,
        status: StoryStatus.closed,
        startedAt: startedAt,
        endedAt: at,
        coverMediaId: coverMediaId,
        lastPostedAt: lastPostedAt,
        createdAt: createdAt,
      ),
    );
  }

  Result<Story> reopen() => Ok(
    Story(
      id: id,
      title: title,
      status: StoryStatus.open,
      startedAt: startedAt,
      coverMediaId: coverMediaId,
      lastPostedAt: lastPostedAt,
      createdAt: createdAt,
    ),
  );
}
