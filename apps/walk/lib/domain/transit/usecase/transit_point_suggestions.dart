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
  static const _lookupBudget = Duration(seconds: 10);

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
  Future<void> saveAs(PlaceKind kind, TransitPoint p) =>
      _places.save(Place(kind: kind, lat: p.lat, lng: p.lng, label: p.label));

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
      final top = frequentPlaces(stays, limit: frequentLimit);
      // 이름 조회는 동시에, 전체 시간 예산 안에서만. 못 얻은 곳은 라벨을 비워 둔다(화면이 대신 보인다).
      final names = await Future.wait([
        for (final p in top) _name(p.lat, p.lng),
      ]);
      return [
        for (var i = 0; i < top.length; i++)
          TransitPoint(
            lat: top[i].lat,
            lng: top[i].lng,
            label: names[i] ?? '',
            source: TransitPointSource.frequent,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _name(double lat, double lng) async {
    try {
      // then<String?> 으로 타입을 넓혀 두어야 onTimeout 이 null 을 돌려줄 수 있다.
      return await _namer
          .nameFor(lat, lng)
          .then<String?>((name) => name)
          .timeout(_lookupBudget, onTimeout: () => null);
    } catch (_) {
      return null;
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
    return [...track.stays]..sort((a, b) => a.start.compareTo(b.start));
  }
}
