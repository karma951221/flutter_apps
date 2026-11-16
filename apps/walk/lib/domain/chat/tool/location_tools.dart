import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../location/entity/location_point.dart';
import '../../location/entity/stay.dart';
import '../../location/geo/geo_math.dart';
import '../../location/recorder/location_recorder.dart';
import '../../location/recorder/recorder_status.dart';
import '../../location/repository/location_repository.dart';
import '../../location/usecase/frequent_places.dart';
import '../../location/usecase/location_sync.dart';
import '../../location/usecase/open_end.dart';
import '../../location/usecase/stay_namer.dart';
import '../../location/usecase/track_analyzer.dart';
import '../chat_model.dart';
import 'tool_input.dart';
import 'tool_result.dart';
import 'tool_summary.dart';

/// 물어보기 모델이 위치 기록(머문 곳 · 자주 간 곳)을 읽는 도구들.
///
/// 결과에는 좌표를 넣지 않는다 — 장소 이름(못 얻으면 null)과 시간만(스펙 §7-1).
@lazySingleton
class LocationTools {
  LocationTools(
    this._repository,
    this._sync,
    this._recorder,
    this._namer,
    this._clock,
  );

  final LocationRepository _repository;
  final LocationSync _sync;
  final LocationRecorder _recorder;
  final StayNamer _namer;
  final Clock _clock;

  static const visitedName = 'visited_places';
  static const frequentName = 'frequent_places';
  static const names = {visitedName, frequentName};

  static const _visitedMaxDays = 31;
  static const _frequentMaxDays = 366;
  static const _chunkDays = 31;
  static const _maxStays = 150;
  static const _maxLookups = 20;

  /// 한 번 부를 때 새 이름 조회에 쓰는 시간. 넘기면 나머지는 캐시에 있는 이름만.
  static const _lookupBudget = Duration(seconds: 10);
  static const _frequentLimit = 10;

  static const _date = {'type': 'string', 'description': 'YYYY-MM-DD (로컬 날짜)'};

  List<ToolSpec> get definitions => [
    ToolSpec(
      name: visitedName,
      description:
          '위치 기록에서 기간 안에 머문 곳(10분 이상)을 시간순으로 본다. 양 끝 날짜를 포함하고 '
          '최대 31일, 최근 것부터 150곳까지. 장소 이름을 모르면 place 가 null 이다. '
          'recording 은 지금 위치 기록 상태(on · off · blocked · unknown).',
      parameters: _range,
    ),
    ToolSpec(
      name: frequentName,
      description:
          '위치 기록에서 기간 안에 자주 머문 곳 상위 10곳(방문 횟수 · 머문 시간 · 마지막 날)을 본다. '
          '양 끝 날짜를 포함하고 최대 366일.',
      parameters: _range,
    ),
  ];

  static const _range = {
    'type': 'object',
    'properties': {'from': _date, 'to': _date},
    'required': ['from', 'to'],
  };

  Future<ToolResult> run(String name, Map<String, Object?> input) async {
    final kind = chatToolKindOf(name);
    try {
      return switch (name) {
        visitedName => await _visited(input),
        frequentName => await _frequent(input),
        _ => toolError('unknown_tool', kind),
      };
    } catch (_) {
      return toolError('tool_failed', kind);
    }
  }

  Future<ToolResult> _visited(Map<String, Object?> input) async {
    const kind = ChatToolKind.visitedPlaces;
    final range = toolRange(input, maxDays: _visitedMaxDays);
    if (range == null) return toolError('invalid_range', kind);
    final ready = await _prepare();
    if (ready == null) return toolError('location_not_recorded', kind);

    final (track: stays, :openEnd) = await _stays(
      range.from,
      range.end,
      ready.status,
    );
    final kept = stays.length > _maxStays
        ? stays.sublist(stays.length - _maxStays)
        : stays;
    final names = await _names([
      for (final s in kept.reversed) (lat: s.lat, lng: s.lng),
    ]);
    return ToolResult(
      json: jsonEncode({
        'stays': [for (final s in kept) _stayJson(s, names[_key(s)], openEnd)],
        'recording': ready.recording,
        'truncated': stays.length > _maxStays,
        ...range.clampJson,
      }),
      summary: ToolSummary(kind: kind, count: kept.length),
    );
  }

  Future<ToolResult> _frequent(Map<String, Object?> input) async {
    const kind = ChatToolKind.frequentPlaces;
    final range = toolRange(input, maxDays: _frequentMaxDays);
    if (range == null) return toolError('invalid_range', kind);
    final ready = await _prepare();
    if (ready == null) return toolError('location_not_recorded', kind);

    // 긴 기간은 31일 덩어리로 읽어 한 번에 메모리에 올리는 점을 묶는다. 덩어리 경계에 걸친
    // 머묾은 둘로 셀 수 있다(스펙 §6.1 — 허용).
    final stays = <Stay>[];
    var start = range.from;
    while (!start.isAfter(range.to)) {
      final last = DateTime(
        start.year,
        start.month,
        start.day + _chunkDays - 1,
      );
      final chunkTo = last.isAfter(range.to) ? range.to : last;
      final (:track, openEnd: _) = await _stays(
        start,
        DateTime(chunkTo.year, chunkTo.month, chunkTo.day, 23, 59, 59, 999),
        ready.status,
      );
      stays.addAll(track);
      start = DateTime(chunkTo.year, chunkTo.month, chunkTo.day + 1);
    }

    final places = frequentPlaces(stays, limit: _frequentLimit);
    final lastVisit = <String, DateTime>{};
    for (final s in stays) {
      final key = _key(s);
      final prev = lastVisit[key];
      if (prev == null || s.start.isAfter(prev)) lastVisit[key] = s.start;
    }
    final names = await _names([
      for (final p in places) (lat: p.lat, lng: p.lng),
    ]);
    return ToolResult(
      json: jsonEncode({
        'places': [
          for (final p in places)
            {
              'place': names[p.gridKey],
              'visits': p.visits,
              'hours': (p.total.inMinutes / 6).round() / 10,
              'last': lastVisit[p.gridKey] == null
                  ? null
                  : toolDay(lastVisit[p.gridKey]!.toLocal()),
            },
        ],
        'recording': ready.recording,
        ...range.clampJson,
      }),
      summary: ToolSummary(kind: kind, count: places.length),
    );
  }

  // 도우미

  /// 수거 · 점 확인 · 기록 상태. 점이 하나도 없으면 null.
  Future<({RecorderStatus? status, String recording})?> _prepare() async {
    try {
      await _sync.run();
    } catch (_) {
      // 수거 실패는 이미 저장된 점을 읽는 데 지장이 없다.
    }
    if (!await _repository.hasAnyPoint()) return null;
    RecorderStatus? status;
    try {
      status = await _recorder.status();
    } catch (_) {
      status = null;
    }
    final recording = switch (status) {
      RecorderRunning() => 'on',
      RecorderOff() => 'off',
      RecorderBlocked() => 'blocked',
      null => 'unknown',
    };
    return (status: status, recording: recording);
  }

  /// [from] ~ [to](로컬) 머문 곳, 시작 오름차순. 지도 화면과 같은 계산.
  Future<({List<Stay> track, DateTime? openEnd})> _stays(
    DateTime from,
    DateTime to,
    RecorderStatus? status,
  ) async {
    final points = await _repository.pointsAround(from.toUtc(), to.toUtc());
    final sorted = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final openEnd = _openEnd(sorted, status);
    final track = TrackAnalyzer().analyze(
      sorted,
      clipFrom: from.toUtc(),
      clipTo: to.toUtc(),
      openEnd: openEnd,
    );
    final stays = [...track.stays]..sort((a, b) => a.start.compareTo(b.start));
    return (track: stays, openEnd: openEnd);
  }

  DateTime? _openEnd(List<LocationPoint> points, RecorderStatus? status) =>
      status == null ? null : stayOpenEnd(points, status, _clock.now());

  /// 격자별 이름. [spots] 순서(우선순위)로 캐시를 먼저 보고, 없으면 새로 [_maxLookups] 곳까지만 묻는다.
  Future<Map<String, String?>> _names(
    List<({double lat, double lng})> spots,
  ) async {
    final names = <String, String?>{};
    var lookups = 0;
    // Geocoder 가 응답하지 않으면 한 번에 8초씩 걸린다 — 새 조회 전체에 시간 예산을 둔다.
    final deadline = _clock.now().add(_lookupBudget);
    for (final s in spots) {
      final key = gridKey(s.lat, s.lng);
      if (names.containsKey(key)) continue;
      final cached = await _repository.placeName(key);
      if (cached != null) {
        names[key] = cached;
      } else if (lookups < _maxLookups && _clock.now().isBefore(deadline)) {
        lookups++;
        names[key] = await _namer.nameFor(s.lat, s.lng);
      } else {
        names[key] = null;
      }
    }
    return names;
  }

  static String _key(Stay s) => gridKey(s.lat, s.lng);

  static Map<String, Object?> _stayJson(
    Stay s,
    String? place,
    DateTime? openEnd,
  ) {
    final start = s.start.toLocal();
    final end = s.end.toLocal();
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return {
      'date': toolDay(start),
      'start': toolTime(start),
      'end': toolTime(end),
      if (!sameDay) 'end_date': toolDay(end),
      'minutes': s.duration.inMinutes,
      'place': place,
      if (openEnd != null && s.end.isAtSameMomentAs(openEnd)) 'ongoing': true,
    };
  }
}
