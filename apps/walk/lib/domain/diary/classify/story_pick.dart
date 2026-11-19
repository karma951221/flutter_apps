import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_pick.freezed.dart';

/// 저장할 때 AI 가 고른 스토리(스펙 2026-11-19). [StoryClassifier.classify] 의 결과.
@freezed
sealed class StoryPick with _$StoryPick {
  /// 열린 기존 스토리 [storyId] 가 맞다.
  const factory StoryPick.existing({
    required String storyId,
    required String reason,
  }) = StoryPickExisting;

  /// 맞는 스토리가 없다 — 이름이 [title] 인 새 스토리를 만들자.
  const factory StoryPick.create({
    required String title,
    required String reason,
  }) = StoryPickCreate;

  /// AI 가 고르지 못했다(키 없음 · 꺼짐 · 실패 · 잘못된 답) — 지금 기본값 [storyId] 로 조용히 저장한다.
  const factory StoryPick.fallback(String storyId) = StoryPickFallback;
}
