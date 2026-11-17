import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/transit/entity/station_hit.dart';
import '../../domain/transit/entity/transit_path.dart';
import '../../domain/transit/entity/transit_point.dart';
import '../../domain/transit/repository/station_search.dart';
import '../../domain/transit/repository/transit_route_source.dart';
import '../../domain/transit/transit_failure.dart';

/// ODsay 로 대중교통 경로(`searchPubTransPathT`)와 역 · 정류장(`searchStation`)을 찾는다.
///
/// 키는 호출마다 받는다. 두 인터페이스를 한 인스턴스가 구현하고,
/// 등록은 `TransitModule` 이 한다.
@lazySingleton
class OdsayTransitClient implements TransitRouteSource, StationSearch {
  OdsayTransitClient(
    this._client, {
    @ignoreParam Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  static const _base = 'https://api.odsay.com/v1/api/';
  static const _maxStations = 20;

  /// 출발 · 도착 정류장 없음, 검색 결과 없음.
  static const _noRouteCodes = {'-99', '3', '4', '5', '6'};

  @override
  Future<List<TransitPath>> find({
    required TransitPoint from,
    required TransitPoint to,
    required String apiKey,
  }) async {
    final body = await _get(
      '${_base}searchPubTransPathT'
      '?SX=${from.lng}&SY=${from.lat}&EX=${to.lng}&EY=${to.lat}'
      '&SearchPathType=0&apiKey=${Uri.encodeComponent(apiKey)}',
    );
    final result = body['result'];
    final paths = result is Map ? result['path'] : null;
    if (paths is! List) throw const TransitFailure.noRoute();

    final parsed = <TransitPath>[];
    var unparsable = 0;
    for (final path in paths) {
      try {
        parsed.add(_parsePath(path));
      } catch (_) {
        unparsable++;
      }
    }
    if (parsed.isEmpty) {
      // 모든 경로가 해석 실패면 응답 형식 문제 — 경로 없음과 구분한다.
      if (paths.isNotEmpty && unparsable == paths.length) {
        throw const TransitFailure.server('parse');
      }
      throw const TransitFailure.noRoute();
    }
    return parsed;
  }

  @override
  Future<List<StationHit>> search(
    String query, {
    required String apiKey,
  }) async {
    final Map<dynamic, dynamic> body;
    try {
      body = await _get(
        '${_base}searchStation'
        '?stationName=${Uri.encodeQueryComponent(query)}'
        '&stationClass=1,2&apiKey=${Uri.encodeComponent(apiKey)}',
      );
    } on TransitNoRoute {
      return const [];
    }
    final result = body['result'];
    final stations = result is Map ? result['station'] : null;
    if (stations is! List) return const [];

    final subway = <StationHit>[];
    final bus = <StationHit>[];
    for (final raw in stations) {
      final hit = _parseStation(raw);
      if (hit == null) continue;
      (hit.kind == StationKind.subway ? subway : bus).add(hit);
    }
    return [...subway, ...bus].take(_maxStations).toList();
  }

  Future<Map<dynamic, dynamic>> _get(String url) async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(url)).timeout(_timeout);
    } on IOException {
      // SocketException · HandshakeException · TlsException 등.
      throw const TransitFailure.network();
    } on TimeoutException {
      throw const TransitFailure.network();
    } on http.ClientException {
      throw const TransitFailure.network();
    }

    final Object? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw TransitFailure.server('HTTP ${response.statusCode}');
    }
    if (body is! Map) {
      throw TransitFailure.server('HTTP ${response.statusCode}');
    }

    _throwIfError(body['error']);
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      throw TransitFailure.server('HTTP $status');
    }
    return body;
  }

  void _throwIfError(Object? error) {
    if (error == null) return;
    final first = error is List ? (error.isEmpty ? null : error.first) : error;
    if (first is! Map) throw TransitFailure.server('$error');
    final code = '${first['code'] ?? ''}';
    final message = '${first['msg'] ?? first['message'] ?? code}';
    if (code == '-98') throw const TransitFailure.tooClose();
    if (_noRouteCodes.contains(code)) throw const TransitFailure.noRoute();
    if (message.contains('ApiKeyAuthFailed') ||
        (code == '500' && message.contains('ApiKey'))) {
      throw TransitFailure.keyRejected(message);
    }
    if (message.contains('LimitExceeded') || message.contains('초과')) {
      throw const TransitFailure.quotaExceeded();
    }
    throw TransitFailure.server(message);
  }

  TransitPath _parsePath(Object? path) {
    if (path is! Map) throw const FormatException('path');
    final info = path['info'] as Map;
    final legs = <TransitLeg>[];
    for (final raw in path['subPath'] as List) {
      final sub = raw as Map;
      final minutes = (sub['sectionTime'] as num).toInt();
      switch (sub['trafficType']) {
        case 3:
          legs.add(
            TransitLeg.walk(
              minutes: minutes,
              distanceM: (sub['distance'] as num?)?.toInt() ?? 0,
            ),
          );
        case 1:
          final lane = (sub['lane'] as List).first as Map;
          legs.add(
            TransitLeg.subway(
              minutes: minutes,
              lineName: '${lane['name']}',
              subwayCode: (lane['subwayCode'] as num?)?.toInt(),
              start: '${sub['startName']}',
              end: '${sub['endName']}',
              stationCount: (sub['stationCount'] as num?)?.toInt() ?? 0,
              way: '${sub['way'] ?? ''}',
            ),
          );
        case 2:
          legs.add(
            TransitLeg.bus(
              minutes: minutes,
              busNumbers: [
                for (final lane in sub['lane'] as List)
                  '${(lane as Map)['busNo']}',
              ],
              start: '${sub['startName']}',
              end: '${sub['endName']}',
              stationCount: (sub['stationCount'] as num?)?.toInt() ?? 0,
            ),
          );
        default:
          throw const FormatException('trafficType');
      }
    }
    final rides = legs.where((l) => l is! TransitWalkLeg).length;
    return TransitPath(
      totalMinutes: (info['totalTime'] as num).toInt(),
      transferCount: rides > 0 ? rides - 1 : 0,
      fare: (info['payment'] as num?)?.toInt(),
      legs: legs,
    );
  }

  StationHit? _parseStation(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['stationName'];
    final x = raw['x'];
    final y = raw['y'];
    if (name is! String || x is! num || y is! num) return null;
    final isSubway = raw['stationClass'] == 2;
    return StationHit(
      name: name,
      kind: isSubway ? StationKind.subway : StationKind.bus,
      lat: y.toDouble(),
      lng: x.toDouble(),
      detail: isSubway
          ? '${raw['laneName'] ?? ''}'
          : [
              '${raw['arsID'] ?? ''}',
              '${raw['gu'] ?? ''}',
            ].where((part) => part.isNotEmpty).join(' · '),
    );
  }
}

/// [OdsayTransitClient] 하나를 경로 · 역 검색 두 얼굴로 등록한다.
@module
abstract class TransitModule {
  @lazySingleton
  TransitRouteSource transitRouteSource(OdsayTransitClient client) => client;

  @lazySingleton
  StationSearch stationSearch(OdsayTransitClient client) => client;
}
