import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entity/tracker_state.dart';
import '../../domain/entity/walk.dart';

part 'walk_feed_state.freezed.dart';

@freezed
sealed class WalkFeedState with _$WalkFeedState {
  /// `start()` 직후 첫 `watchWalks` 값 전.
  const factory WalkFeedState.loading() = WalkFeedLoading;

  /// [walks] 는 최신순. [tracker] 로 배너 · FAB 를 정한다.
  const factory WalkFeedState.loaded({
    required List<Walk> walks,
    required TrackerState tracker,
  }) = WalkFeedLoaded;

  const factory WalkFeedState.failure(Failure failure) = WalkFeedFailure;
}
