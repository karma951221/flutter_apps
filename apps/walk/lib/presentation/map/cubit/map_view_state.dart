import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/location/entity/day_track.dart';
import '../../../domain/location/entity/frequent_place.dart';
import '../../../domain/location/entity/map_period.dart';

part 'map_view_state.freezed.dart';

@freezed
sealed class MapViewState with _$MapViewState {
  const factory MapViewState.loading(MapPeriod period) = MapViewLoading;
  const factory MapViewState.ready(MapViewData data) = MapViewReady;
  const factory MapViewState.empty(MapPeriod period) = MapViewEmpty;
  const factory MapViewState.failure(MapPeriod period) = MapViewFailure;
}

/// 한 기간의 지도 데이터. [stayNames] 의 키는 `gridKey` — 오늘 보기는 이름을 물어 채우고, 한 달 ·
/// 스토리는 격자 캐시에 있는 것만 채운다(자주 간 곳 · 머문 곳).
@freezed
class MapViewData with _$MapViewData {
  @override
  final MapPeriod period;

  @override
  final DayTrack track;

  @override
  final List<FrequentPlace> frequent;

  @override
  final List<DiaryEntry> entries;

  @override
  final Map<String, String> stayNames;

  const MapViewData({
    required this.period,
    required this.track,
    required this.frequent,
    required this.entries,
    required this.stayNames,
  });
}
