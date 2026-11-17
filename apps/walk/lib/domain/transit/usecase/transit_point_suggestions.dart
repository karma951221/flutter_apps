import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../commute/entity/place.dart';
import '../../commute/repository/place_repository.dart';
import '../../location/entity/stay.dart';
import '../../location/recorder/location_recorder.dart';
import '../../location/recorder/recorder_status.dart';
import '../../location/repository/location_repository.dart';
import '../../location/usecase/frequent_places.dart';
import '../../location/usecase/open_end.dart';
import '../../location/usecase/stay_namer.dart';
import '../../location/usecase/track_analyzer.dart';
import '../entity/transit_point.dart';
import '../repository/recent_points.dart';

/// 출발 · 도착 후보 묶음. 현재 위치는 화면이 따로 얻는다.
class TransitSuggestions {
  const TransitSuggestions({
    this.home,
    this.work,
    this.frequent = const [],
    this.recent = const [],
  });

  final TransitPoint? home;
  final TransitPoint? work;
  final List<TransitPoint> frequent;
  final List<TransitPoint> recent;
}

/// 길찾기 후보 — 집 · 회사(통근 설정), 최근 30일 자주 간 곳(위치 기록), 최근 장소.
@injectable
class TransitPointSuggestions {
  TransitPointSuggestions(
    this._places,
    this._recent,
    this._locations,
    this._namer,
    this._recorder,
    this._clock,
  );

  final PlaceRepository _places;
  final RecentPoints _recent;
  final LocationRepository _locations;
  final StayNamer _namer;
  final LocationRecorder _recorder;
  final Clock _clock;

  static const frequentDays = 30;
  static const frequentLimit = 5;

  Future<TransitSuggestions> load() async {
    final recent = await _recent.load();
    return TransitSuggestions(
      home: _place(PlaceKind.home, TransitPointSource.home),
      work: _place(PlaceKind.work, TransitPointSource.work),
      frequent: await _frequent(),
      recent: recent,
    );
  }

  /// 집 · 회사로 저장해 다음부터 후보에 올린다.
  Future<void> saveAs(PlaceKind kind, TransitPoint p) => _places.save(
    Place(kind: kind, lat: p.lat, lng: p.lng, label: p.label),
  );

  TransitPoint? _place(PlaceKind kind, TransitPointSource source) {
    final place = _places.load(kind);
    if (place == null) return null;
    return TransitPoint(
      lat: place.lat,
      lng: place.lng,
      label: place.label,
      source: source,
    );
  }

  /// 위치 기록이 없거나 어디서든 실패하면 빈 목록.
  Future<List<TransitPoint>> _frequent() async {
    try {
      if (!await _locations.hasAnyPoint()) return const [];
      final to = _clock.now();
      final from = to.subtract(const Duration(days: frequentDays));
      final stays = await _stays(from, to);
      final result = <TransitPoint>[];
      for (final p in frequentPlaces(stays, limit: frequentLimit)) {
        final name = await _namer.nameFor(p.lat, p.lng);
        if (name == null) continue;
        result.add(
          TransitPoint(
            lat: p.lat,
            lng: p.lng,
            label: name,
            source: TransitPointSource.frequent,
          ),
        );
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// 지도 화면 · 물어보기 도구와 같은 계산.
  Future<List<Stay>> _stays(DateTime from, DateTime to) async {
    RecorderStatus? status;
    try {
      status = await _recorder.status();
    } catch (_) {
      status = null;
    }
    final points = await _locations.pointsAround(from.toUtc(), to.toUtc());
    final sorted = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final openEnd = status == null
        ? null
        : stayOpenEnd(sorted, status, _clock.now());
    final track = TrackAnalyzer().analyze(
      sorted,
      clipFrom: from.toUtc(),
      clipTo: to.toUtc(),
      openEnd: openEnd,
    );
    return track.stays;
  }
}
