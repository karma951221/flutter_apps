import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/location/entity/day_track.dart';
import '../../../domain/location/entity/location_point.dart';
import '../../../domain/location/entity/map_period.dart';
import '../../../domain/location/entity/stay.dart';
import '../../../domain/location/entity/track_segment.dart';
import '../../../domain/location/geo/geo_math.dart';
import '../../../domain/location/recorder/location_recorder.dart';
import '../../../domain/location/recorder/recorder_status.dart';
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
    this._recorder,
    this._clock,
  ) : super(MapViewState.loading(MapPeriod.day(_clock.now())));

  /// 한 달 · 긴 스토리에서 그리는 선의 단순화 허용 오차.
  static const _simplifyToleranceM = 30.0;

  /// 스토리 기간이 이보다 길면 그리는 선을 단순화한다(끝나지 않은 스토리는 지금까지).
  static const _longStory = Duration(days: 2);

  final LocationRepository _locations;
  final DiaryRepository _diary;
  final LocationSync _sync;
  final StayNamer _namer;
  final LocationRecorder _recorder;
  final Clock _clock;

  MapPeriod? _period;
  int _generation = 0;

  /// 로딩 표시를 내고, 네이티브 inbox 를 먼저 수거한 뒤 [period] 를 읽는다(지도를 열 때 · 기간을
  /// 바꿀 때 · 다시 시도). 수거는 [LocationSync.run] 이 겹치지 않게 하나로 묶는다.
  Future<void> show(MapPeriod period) => _load(period, showLoading: true);

  /// 로딩 표시 없이, 네이티브 inbox 를 먼저 수거한 뒤 현재 기간을 다시 읽는다(앱 복귀 ·
  /// 위에 얹힌 화면이 걷힐 때 · 기록을 켠 뒤).
  Future<void> refresh() async {
    final period = _period;
    if (period == null) return;
    await _load(period, showLoading: false);
  }

  /// 수거가 실패해도 저장된 데이터로 읽는다. 더 늦게 부른 show · refresh 가 이긴다.
  Future<void> _load(MapPeriod period, {required bool showLoading}) async {
    _period = period;
    final generation = ++_generation;
    if (showLoading) emit(MapViewState.loading(period));
    try {
      await _sync.run();
    } catch (e, s) {
      debugPrint('map sync failed: $e\n$s');
    }
    if (isClosed || generation != _generation) return;
    try {
      final next = await _read(period, generation);
      if (next == null || isClosed || generation != _generation) return;
      emit(next);
    } catch (e, s) {
      debugPrint('map load failed: $e\n$s');
      if (isClosed || generation != _generation) return;
      emit(MapViewState.failure(period));
    }
  }

  Future<MapViewState?> _read(MapPeriod period, int generation) async {
    final now = _clock.now();
    final bounds = period.bounds(now);
    // 경계 바깥 이웃 점까지 읽어야 기간을 넘는 · 아직 이어지는 머문 곳이 보인다.
    final points = await _locations.pointsAround(
      bounds.from.toUtc(),
      bounds.to.toUtc(),
    );
    final entries = await _diary.locatedEntriesBetween(bounds.from, bounds.to);
    final openEnd = await _openEnd(points, now);

    var track = TrackAnalyzer().analyze(
      points,
      clipFrom: bounds.from.toUtc(),
      clipTo: bounds.to.toUtc(),
      openEnd: openEnd,
    );
    // 자주 간 곳 · 머문 곳은 단순화 전 점으로 구한다 — 단순화는 그리는 선만.
    final frequent = frequentPlaces(track.stays);
    final simplified = switch (period) {
      MonthPeriod() => true,
      StoryPeriod() => bounds.to.difference(bounds.from) > _longStory,
      DayPeriod() => false,
    };
    if (simplified) {
      track = DayTrack(
        segments: [
          for (final s in track.segments)
            TrackSegment(
              points: simplify(s.points, toleranceM: _simplifyToleranceM),
              mode: s.mode,
            ),
        ],
        stays: track.stays,
      );
    }

    final names = switch (period) {
      DayPeriod() => await _lookupNames(track.stays, generation),
      MonthPeriod() || StoryPeriod() => await _cachedNames([
        for (final f in frequent) f.gridKey,
        for (final s in track.stays) gridKey(s.lat, s.lng),
      ], generation),
    };
    if (names == null) return null;

    if (track.isEmpty && entries.isEmpty) return MapViewState.empty(period);
    return MapViewState.ready(
      MapViewData(
        period: period,
        track: track,
        frequent: frequent,
        entries: entries,
        stayNames: names,
      ),
    );
  }

  /// 마지막 머문 곳을 지금까지 이을 때만 지금(UTC) — 꺼져 있던 시간을 머문 곳으로 지어내지 않게.
  /// 기록 중이고, 지금 서비스가 마지막 점 이전부터 끊김 없이 살아 있고, 마지막 점이 정지 감지 점이거나
  /// 정지 감지가 꺼져 있을 때(꺼져 있으면 가만히 있는 동안 점이 안 남는다). 상태를 못 읽으면 잇지 않는다.
  Future<DateTime?> _openEnd(List<LocationPoint> points, DateTime now) async {
    if (points.isEmpty) return null;
    final RecorderStatus status;
    try {
      status = await _recorder.status();
    } catch (e, s) {
      debugPrint('map recorder status failed: $e\n$s');
      return null;
    }
    if (status case RecorderRunning(
      :final stillDetection,
      recordingSince: final since?,
    )) {
      final last = points.last;
      if (last.recordedAt.isBefore(since)) return null;
      if (!last.stillStart && stillDetection) return null;
      return now.toUtc();
    }
    return null;
  }

  /// 오늘 보기: 캐시에 없으면 이름을 묻는다(네트워크). 더 새 읽기가 시작되면 null.
  Future<Map<String, String>?> _lookupNames(
    List<Stay> stays,
    int generation,
  ) async {
    final names = <String, String>{};
    final tried = <String>{};
    for (final stay in stays) {
      if (isClosed || generation != _generation) return null;
      final key = gridKey(stay.lat, stay.lng);
      if (!tried.add(key)) continue;
      final name = await _namer.nameFor(stay.lat, stay.lng);
      if (name != null) names[key] = name;
    }
    return names;
  }

  /// 한 달 · 스토리: 격자 캐시에 있는 이름만(네트워크 없음). 더 새 읽기가 시작되면 null.
  Future<Map<String, String>?> _cachedNames(
    List<String> keys,
    int generation,
  ) async {
    final names = <String, String>{};
    for (final key in keys.toSet()) {
      if (isClosed || generation != _generation) return null;
      final name = await _locations.placeName(key);
      if (name != null) names[key] = name;
    }
    return names;
  }
}
