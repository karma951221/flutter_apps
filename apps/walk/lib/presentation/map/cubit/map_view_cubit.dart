import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/location/entity/day_track.dart';
import '../../../domain/location/entity/map_period.dart';
import '../../../domain/location/entity/track_segment.dart';
import '../../../domain/location/geo/geo_math.dart';
import '../../../domain/location/repository/location_repository.dart';
import '../../../domain/location/usecase/frequent_places.dart';
import '../../../domain/location/usecase/location_sync.dart';
import '../../../domain/location/usecase/stay_namer.dart';
import '../../../domain/location/usecase/track_analyzer.dart';
import '../../../domain/location/usecase/track_simplifier.dart';
import 'map_view_state.dart';

/// 지도 화면이 그릴 한 기간의 이동선 · 머문 곳 · 일기를 읽어 온다.
@injectable
class MapViewCubit extends Cubit<MapViewState> {
  MapViewCubit(
    this._locations,
    this._diary,
    this._sync,
    this._namer,
    this._clock,
  ) : super(MapViewState.loading(MapPeriod.day(_clock.now())));

  static const entryLimit = 300;
  static const _monthToleranceM = 30.0;

  final LocationRepository _locations;
  final DiaryRepository _diary;
  final LocationSync _sync;
  final StayNamer _namer;
  final Clock _clock;

  MapPeriod? _period;
  int _generation = 0;

  Future<void> show(MapPeriod period) => _load(period, showLoading: true);

  /// 네이티브 inbox 를 먼저 수거한 뒤 현재 기간을 다시 읽는다.
  Future<void> refresh() async {
    final period = _period;
    if (period == null) return;
    await _sync.run();
    if (isClosed) return;
    await _load(period, showLoading: false);
  }

  Future<void> _load(MapPeriod period, {required bool showLoading}) async {
    _period = period;
    final generation = ++_generation;
    if (showLoading) emit(MapViewState.loading(period));

    final bounds = period.bounds(_clock.now());
    final points = await _locations.pointsBetween(
      bounds.from.toUtc(),
      bounds.to.toUtc(),
    );
    final found = await _diary.searchEntries(
      from: bounds.from,
      to: bounds.to,
      storyId: switch (period) {
        StoryPeriod(:final story) => story.id,
        _ => null,
      },
      limit: entryLimit,
    );
    final entries = [
      for (final e in found)
        if (e.location?.hasCoordinates ?? false) e,
    ];

    var track = TrackAnalyzer().analyze(
      points,
      clipFrom: bounds.from.toUtc(),
      clipTo: bounds.to.toUtc(),
    );
    final frequent = frequentPlaces(track.stays);
    if (period is MonthPeriod) {
      track = DayTrack(
        segments: [
          for (final s in track.segments)
            TrackSegment(
              points: simplify(s.points, toleranceM: _monthToleranceM),
              mode: s.mode,
            ),
        ],
        stays: track.stays,
      );
    }

    final names = <String, String>{};
    if (period is DayPeriod) {
      for (final stay in track.stays) {
        final key = gridKey(stay.lat, stay.lng);
        if (names.containsKey(key)) continue;
        final name = await _namer.nameFor(stay.lat, stay.lng);
        if (name != null) names[key] = name;
      }
    }

    if (isClosed || generation != _generation) return;
    if (track.isEmpty && entries.isEmpty) {
      emit(MapViewState.empty(period));
      return;
    }
    emit(
      MapViewState.ready(
        MapViewData(
          period: period,
          track: track,
          frequent: frequent,
          entries: entries,
          stayNames: names,
        ),
      ),
    );
  }
}
