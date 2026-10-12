import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/diary_failure.dart';
import '../../../domain/diary/entity/story.dart';

part 'story_manage_state.freezed.dart';

/// 스토리 관리 화면(스펙 §6.3). 스토리는 `StoryOrder.split` 순서 그대로.
@freezed
class StoryManageState with _$StoryManageState {
  /// 열린 스토리(기본 스토리 포함), lastPostedAt 최신순.
  @override
  final List<Story> open;

  /// 닫힌 스토리(보관함), endedAt 최신순.
  @override
  final List<Story> archived;

  /// 첫 스토리 목록을 아직 받지 못했다.
  @override
  final bool loading;

  /// 스토리 목록을 읽지 못했다.
  @override
  final bool failed;

  /// 마지막 동작이 일기 규칙에 걸렸다. 동작을 시작할 때 비운다.
  @override
  final DiaryFailure? error;

  /// 마지막 동작이 규칙 밖의 오류(DB)로 실패했다. 동작을 시작할 때 비운다.
  @override
  final bool actionFailed;

  /// 마지막 [StoryManageCubit.create] 로 만든 스토리. 지난 기간이면 화면이 '일상' 기록 옮기기를 제안한다.
  @override
  final Story? created;

  const StoryManageState({
    this.open = const [],
    this.archived = const [],
    this.loading = true,
    this.failed = false,
    this.error,
    this.actionFailed = false,
    this.created,
  });
}
