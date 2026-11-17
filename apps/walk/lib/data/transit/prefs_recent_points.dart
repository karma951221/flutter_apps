import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/transit/entity/transit_point.dart';
import '../../domain/transit/repository/recent_points.dart';

/// 최근에 고른 장소 10개(최신 순). 같은 좌표(cacheKey)는 하나만 남는다.
@LazySingleton(as: RecentPoints)
class PrefsRecentPoints implements RecentPoints {
  PrefsRecentPoints(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'transit.recent';
  static const limit = 10;

  @override
  Future<List<TransitPoint>> load() async {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      final json = jsonDecode(raw);
      if (json is! List) return const [];
      return [for (final item in json) ?TransitPoint.fromJson(item)];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> add(TransitPoint p) async {
    final next = [
      p,
      for (final old in await load())
        if (old.cacheKey != p.cacheKey) old,
    ].take(limit);
    await _prefs.setString(
      key,
      jsonEncode([for (final point in next) point.toJson()]),
    );
  }
}
