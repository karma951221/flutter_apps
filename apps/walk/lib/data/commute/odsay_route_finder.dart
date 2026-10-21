import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:walk/core/config/commute_api_keys.dart';
import 'package:walk/data/commute/subway_line_codes.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';
import 'package:walk/domain/commute/repository/route_finder.dart';

/// ODsay `searchPubTransPathT` 로 지하철 경로를 찾는다.
@LazySingleton(as: RouteFinder)
class OdsayRouteFinder implements RouteFinder {
  OdsayRouteFinder(
    this._client,
    this._keys, {
    @ignoreParam Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout;

  final http.Client _client;
  final CommuteApiKeys _keys;
  final Duration _timeout;

  /// 출발 · 도착 정류장 없음, 검색 결과 없음, 너무 가까움.
  static const _noRouteCodes = {'-98', '-99', '3', '4', '5', '6'};

  @override
  Future<List<TransitRoute>> find({required Place from, required Place to}) async {
    final uri = Uri.parse(
      'https://api.odsay.com/v1/api/searchPubTransPathT'
      '?SX=${from.lng}&SY=${from.lat}&EX=${to.lng}&EY=${to.lat}'
      '&SearchPathType=1&apiKey=${Uri.encodeComponent(_keys.odsay)}',
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on SocketException {
      throw const CommuteFailure.network();
    } on TimeoutException {
      throw const CommuteFailure.network();
    } on http.ClientException {
      throw const CommuteFailure.network();
    }

    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw CommuteFailure.server('HTTP ${response.statusCode}');
    }
    if (body is! Map) throw CommuteFailure.server('HTTP ${response.statusCode}');

    _throwIfError(body['error']);

    final result = body['result'];
    final paths = result is Map ? result['path'] : null;
    if (paths is! List) throw const CommuteFailure.noRoute();

    final routes = <TransitRoute>[];
    for (final path in paths) {
      try {
        final route = _parsePath(path);
        if (route != null) routes.add(route);
      } catch (_) {
        // 해석 못 하는 경로는 버린다.
      }
    }
    if (routes.isEmpty) throw const CommuteFailure.noRoute();
    return routes;
  }

  void _throwIfError(Object? error) {
    if (error == null) return;
    final first = error is List ? (error.isEmpty ? null : error.first) : error;
    if (first is! Map) throw CommuteFailure.server('$error');
    final code = '${first['code'] ?? ''}';
    final message = '${first['msg'] ?? first['message'] ?? code}';
    if (_noRouteCodes.contains(code)) throw const CommuteFailure.noRoute();
    throw CommuteFailure.server(message);
  }

  /// 버스 등 지하철 · 도보가 아닌 구간이 있으면 null.
  TransitRoute? _parsePath(Object? path) {
    if (path is! Map) return null;
    final info = path['info'] as Map;
    final subPath = path['subPath'] as List;
    final legs = <RouteLeg>[];
    for (final raw in subPath) {
      final sub = raw as Map;
      final minutes = (sub['sectionTime'] as num).toInt();
      switch (sub['trafficType']) {
        case 3:
          legs.add(RouteLeg.walk(minutes: minutes));
        case 1:
          final lane = (sub['lane'] as List).first as Map;
          legs.add(
            RouteLeg.subway(
              minutes: minutes,
              lineName: '${lane['name']}',
              odsayLaneCode: (lane['subwayCode'] as num).toInt(),
              startStation: normalizeStationName('${sub['startName']}'),
              endStation: normalizeStationName('${sub['endName']}'),
              wayCode: (sub['wayCode'] as num?)?.toInt() ?? 0,
              wayName: '${sub['way'] ?? ''}',
              stationCount: (sub['stationCount'] as num).toInt(),
            ),
          );
        default:
          return null;
      }
    }
    final subways = legs.whereType<SubwayLeg>().length;
    return TransitRoute(
      totalMinutes: (info['totalTime'] as num).toInt(),
      transferCount: subways > 0 ? subways - 1 : 0,
      legs: legs,
    );
  }
}
