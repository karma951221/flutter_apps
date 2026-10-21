import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:walk/core/config/commute_api_keys.dart';
import 'package:walk/domain/commute/subway_line_codes.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/entity/train_arrival.dart';
import 'package:walk/domain/commute/repository/subway_arrival_source.dart';

/// 서울 열린데이터광장 `realtimeStationArrival` 로 도착 정보를 읽는다.
@LazySingleton(as: SubwayArrivalSource)
class SeoulSubwayArrivalSource implements SubwayArrivalSource {
  SeoulSubwayArrivalSource(
    this._client,
    this._keys,
    this._clock, {
    @ignoreParam Duration timeout = const Duration(seconds: 8),
  }) : _timeout = timeout;

  final http.Client _client;
  final CommuteApiKeys _keys;
  final Clock _clock;
  final Duration _timeout;

  static const _maxTrains = 2;

  @override
  Future<List<TrainArrival>> arrivals({
    required String station,
    required int odsayLaneCode,
    required int wayCode,
  }) async {
    final subwayId = seoulSubwayIdFor(odsayLaneCode);
    if (subwayId == null) return const [];

    final uri = Uri.parse(
      'http://swopenapi.seoul.go.kr/api/subway/${_keys.seoulSubway}'
      '/json/realtimeStationArrival/0/20/${Uri.encodeComponent(station)}',
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
    if (body is! Map<String, dynamic>) {
      throw CommuteFailure.server('HTTP ${response.statusCode}');
    }

    if (_isNoData(body)) return const [];

    final list = body['realtimeArrivalList'];
    if (list is! List) return const [];

    final directions = wayCode == 1 ? const {'상행', '내선'} : const {'하행', '외선'};
    final now = _clock.now();
    final parsed = <_Row>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        final row = _parse(item, subwayId, directions, now);
        if (row != null) parsed.add(row);
      } catch (_) {
        // 파싱 실패 행은 버린다.
      }
    }
    parsed.sort(_compare);
    return [for (final row in parsed.take(_maxTrains)) row.arrival];
  }

  /// 오류면 던지고, 데이터 없음(INFO-200)이면 true.
  bool _isNoData(Map<String, dynamic> body) {
    final nested = body['errorMessage'];
    final Map<String, dynamic> error;
    if (nested is Map<String, dynamic>) {
      error = nested;
    } else if (body.containsKey('code') && body['realtimeArrivalList'] == null) {
      error = body;
    } else {
      return false;
    }
    final code = '${error['code'] ?? ''}';
    if (code == 'INFO-000') return false;
    if (code == 'INFO-200') return true;
    throw CommuteFailure.server('${error['message'] ?? code}');
  }

  _Row? _parse(
    Map<dynamic, dynamic> item,
    int subwayId,
    Set<String> directions,
    DateTime now,
  ) {
    if ('${item['subwayId']}' != '$subwayId') return null;
    if (!directions.contains('${item['updnLine']}')) return null;

    final message = '${item['arvlMsg2'] ?? ''}';
    final ordkey = '${item['ordkey'] ?? ''}';
    int? sortKey;
    int? stationsAway;
    final ord = RegExp(r'^\d{2}(\d{3})').firstMatch(ordkey);
    if (ord != null) {
      stationsAway = int.parse(ord.group(1)!);
      sortKey = int.parse(ordkey.substring(0, 5));
    } else {
      stationsAway = _stationsFromMessage(message);
    }

    final minutes = _minutes(item, message, now);
    final line = '${item['trainLineNm'] ?? ''}';
    final destination = line.contains(' - ') ? line.split(' - ').first.trim() : null;

    return _Row(
      sortKey: sortKey,
      arrival: TrainArrival(
        minutes: minutes,
        stationsAway: stationsAway,
        message: message,
        destination: (destination == null || destination.isEmpty) ? null : destination,
      ),
    );
  }

  int? _stationsFromMessage(String message) {
    final nth = RegExp(r'\[(\d+)\]번째 전역').firstMatch(message);
    if (nth != null) return int.parse(nth.group(1)!);
    if (RegExp(r'전역 (도착|출발|진입)').hasMatch(message)) return 1;
    if (RegExp(r'당역 (도착|진입|출발)').hasMatch(message)) return 0;
    return null;
  }

  int? _minutes(Map<dynamic, dynamic> item, String message, DateTime now) {
    final barvlDt = int.tryParse('${item['barvlDt'] ?? ''}') ?? 0;
    if (barvlDt > 0) {
      final received = _parseSeoulTime('${item['recptnDt'] ?? ''}');
      final elapsed = received == null ? 0 : now.difference(received).inSeconds;
      return math.max(0, ((barvlDt - elapsed) / 60).ceil());
    }
    final m = RegExp(r'(\d+)분( (\d+)초)? 후').firstMatch(message);
    if (m != null) {
      final minutes = int.parse(m.group(1)!);
      final seconds = int.tryParse(m.group(3) ?? '') ?? 0;
      return minutes + (seconds > 0 ? 1 : 0);
    }
    final code = '${item['arvlCd'] ?? ''}';
    if (code == '0' || code == '1') return 0;
    return null;
  }

  /// `yyyy-MM-dd HH:mm:ss`(서울 현지, UTC+9)를 UTC 시각으로. 실패하면 null.
  DateTime? _parseSeoulTime(String text) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})').firstMatch(text.trim());
    if (m == null) return null;
    final p = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
    return DateTime.utc(p[0], p[1], p[2], p[3], p[4], p[5]).subtract(const Duration(hours: 9));
  }

  static int _compare(_Row a, _Row b) {
    const big = 1 << 30;
    final byKey = (a.sortKey ?? big).compareTo(b.sortKey ?? big);
    if (byKey != 0) return byKey;
    final byStations = (a.arrival.stationsAway ?? big).compareTo(b.arrival.stationsAway ?? big);
    if (byStations != 0) return byStations;
    return (a.arrival.minutes ?? big).compareTo(b.arrival.minutes ?? big);
  }
}

class _Row {
  const _Row({required this.sortKey, required this.arrival});
  final int? sortKey;
  final TrainArrival arrival;
}
