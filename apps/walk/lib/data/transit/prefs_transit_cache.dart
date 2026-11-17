import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/transit/entity/station_hit.dart';
import '../../domain/transit/entity/transit_path.dart';
import '../../domain/transit/repository/transit_cache.dart';

/// 경로는 메모리(10분), 역 검색은 prefs(7일 · 최근 100개)에 둔다.
@LazySingleton(as: TransitCache)
class PrefsTransitCache implements TransitCache {
  PrefsTransitCache(this._prefs, this._clock);

  final SharedPreferences _prefs;
  final Clock _clock;

  static const stationKey = 'transit.stationCache';
  static const routeTtl = Duration(minutes: 10);
  static const stationTtl = Duration(days: 7);
  static const maxStations = 100;

  final _routes = <String, ({List<TransitPath> paths, DateTime fetchedAt})>{};

  @override
  ({List<TransitPath> paths, DateTime fetchedAt})? routes(String key) {
    final hit = _routes[key];
    if (hit == null) return null;
    if (_clock.now().difference(hit.fetchedAt) >= routeTtl) {
      _routes.remove(key);
      return null;
    }
    return hit;
  }

  @override
  void putRoutes(String key, List<TransitPath> paths) {
    _routes[key] = (paths: List.unmodifiable(paths), fetchedAt: _clock.now());
  }

  /// 앞뒤 공백 · 대소문자 · 안의 공백을 무시한다.
  static String normalize(String query) =>
      query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// 저장된 맵(정규화한 검색어 → {at, hits}). 깨졌으면 빈 맵.
  Map<String, Map<String, Object?>> _read() {
    final raw = _prefs.getString(stationKey);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      return {
        for (final e in json.entries)
          if (e.key is String && e.value is Map)
            e.key as String: Map<String, Object?>.from(e.value as Map),
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<List<StationHit>?> stations(String query) async {
    final entry = _read()[normalize(query)];
    if (entry == null) return null;
    final at = entry['at'];
    final hits = entry['hits'];
    if (at is! int || hits is! List) return null;
    final age = _clock.now().difference(
      DateTime.fromMillisecondsSinceEpoch(at),
    );
    if (age >= stationTtl) return null;
    final parsed = [for (final h in hits) StationHit.fromJson(h)];
    if (parsed.contains(null)) return null;
    return parsed.whereType<StationHit>().toList();
  }

  @override
  Future<void> putStations(String query, List<StationHit> hits) async {
    final all = _read();
    all[normalize(query)] = {
      'at': _clock.now().millisecondsSinceEpoch,
      'hits': [for (final h in hits) h.toJson()],
    };
    if (all.length > maxStations) {
      final newestFirst = all.entries.toList()
        ..sort((a, b) => _at(b.value).compareTo(_at(a.value)));
      all
        ..clear()
        ..addEntries(newestFirst.take(maxStations));
    }
    await _prefs.setString(stationKey, jsonEncode(all));
  }

  static int _at(Map<String, Object?> entry) {
    final at = entry['at'];
    return at is int ? at : 0;
  }
}
