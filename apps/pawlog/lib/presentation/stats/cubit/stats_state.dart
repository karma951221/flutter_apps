import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/stats/entity/period_stats.dart';
import '../../../domain/stats/entity/walk_records.dart';

part 'stats_state.freezed.dart';

@freezed
sealed class StatsState with _$StatsState {
  /// `start()` 직후 첫 `watchWalks` 값 전.
  const factory StatsState.loading() = StatsLoading;

  /// [offset] 0 = 지금 기간. [isEmpty] 는 산책이 하나도 없을 때. [now] 는 계산에 쓴 시각 —
  /// 기간 라벨의 연도 표기를 정한다.
  const factory StatsState.loaded({
    required PeriodStats stats,
    required WalkRecords records,
    required int offset,
    required bool canShowPrevious,
    required bool canShowNext,
    required bool isEmpty,
    required DateTime now,
  }) = StatsLoaded;

  const factory StatsState.failure(Failure failure) = StatsFailure;
}
