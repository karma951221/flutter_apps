import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/stats/entity/period_summary.dart';
import '../../../domain/tracking/entity/tracker_state.dart';
import '../../../domain/walk/entity/walk.dart';

part 'walk_feed_state.freezed.dart';

@freezed
sealed class WalkFeedState with _$WalkFeedState {
  /// `start()` 직후 첫 `watchWalks` 값 전.
  const factory WalkFeedState.loading() = WalkFeedLoading;

  /// [walks] 는 최신순으로 지금까지 읽은 페이지(즐겨찾기만 보기면 즐겨찾기만). [tracker] 로
  /// 배너 · FAB 를 정한다. [weekSummary] 는 맨 위 요약 줄 — 페이지 · 필터와 무관하게
  /// 이번 주 전체. [hasMore] 면 다음 페이지가 있을 수 있고, [isLoadingMore] 는 그 페이지를
  /// 읽는 중이다.
  const factory WalkFeedState.loaded({
    required List<Walk> walks,
    required TrackerState tracker,
    @Default(PeriodSummary.empty) PeriodSummary weekSummary,
    @Default(false) bool favoritesOnly,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
  }) = WalkFeedLoaded;

  const factory WalkFeedState.failure(Failure failure) = WalkFeedFailure;
}
