import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/core/config/commute_api_keys.dart';
import 'package:walk/data/commute/seoul_subway_arrival_source.dart';
import 'package:walk/domain/commute/commute_failure.dart';

class _FixedClock extends Clock {
  _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

String _fixture(String name) =>
    File('test/fixtures/commute/$name').readAsStringSync();

// recptnDt 08:00:00 (서울) == 2026-10-20 23:00:00 UTC.
final _received = DateTime.utc(2026, 10, 20, 23);

http.Response _json(String body) => http.Response.bytes(
  utf8.encode(body),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  const keys = CommuteApiKeys(odsay: 'o', seoulSubway: 'KEY123');

  SeoulSubwayArrivalSource build(
    Future<http.Response> Function(http.Request) handler, {
    DateTime? now,
    Duration timeout = const Duration(seconds: 8),
  }) => SeoulSubwayArrivalSource(
    MockClient(handler),
    keys,
    _FixedClock(now ?? _received.add(const Duration(seconds: 30))),
    timeout: timeout,
  );

  Map<String, dynamic> row({
    String subwayId = '1007',
    String updn = '상행',
    String line = '장암행 - 상도방면',
    String barvlDt = '0',
    String msg2 = '',
    String cd = '99',
    String? ordkey,
    String rec = '2026-10-21 08:00:00',
  }) => {
    'subwayId': subwayId,
    'updnLine': updn,
    'trainLineNm': line,
    'statnNm': '장승배기',
    'barvlDt': barvlDt,
    'arvlMsg2': msg2,
    'arvlMsg3': '',
    'arvlCd': cd,
    'recptnDt': rec,
    'ordkey': ?ordkey,
  };

  String body(List<Map<String, dynamic>> rows) => jsonEncode({
    'errorMessage': {
      'status': 200,
      'code': 'INFO-000',
      'message': '정상 처리되었습니다.',
    },
    'realtimeArrivalList': rows,
  });

  test('parses two nearest trains in direction', () async {
    final source = build(
      (_) async => _json(_fixture('seoul_arrival_jangseungbaegi.json')),
    );

    final up = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(up, hasLength(2));
    // 30초 경과: (240-30)/60 → 4, (420-30)/60 → 7.
    expect(up[0].stationsAway, 2);
    expect(up[0].minutes, 4);
    expect(up[0].destination, '장암행');
    expect(up[0].message, '[2]번째 전역 (남성)');
    expect(up[0].estimated, isFalse);
    expect(up[1].stationsAway, 5);
    expect(up[1].minutes, 7);
    expect(up[1].destination, '대림행');

    final down = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 2,
    );
    expect(down.map((t) => t.stationsAway), [3, 6]);
    expect(down.map((t) => t.minutes), [3, 8]);
  });

  test('filters other lines and opposite direction', () async {
    final rows = [
      row(
        subwayId: '1077',
        barvlDt: '30',
        msg2: '[1]번째 전역',
        ordkey: '01001신분당0',
      ),
      row(updn: '하행', barvlDt: '30', msg2: '[1]번째 전역', ordkey: '01001석남0'),
      row(barvlDt: '600', msg2: '[4]번째 전역', ordkey: '01004장암0'),
    ];
    final source = build((_) async => _json(body(rows)));

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result, hasLength(1));
    expect(result.single.stationsAway, 4);
  });

  test('wayCode 2 on a loop line accepts 외선', () async {
    final rows = [
      row(subwayId: '1002', updn: '외선', barvlDt: '120', ordkey: '01002성수0'),
      row(subwayId: '1002', updn: '내선', barvlDt: '60', ordkey: '01001성수0'),
    ];
    final source = build((_) async => _json(body(rows)));

    final result = await source.arrivals(
      station: '잠실',
      odsayLaneCode: 2,
      wayCode: 2,
    );

    expect(result.single.stationsAway, 2);
  });

  test('clamps to zero when data is older than barvlDt', () async {
    final source = build(
      (_) async => _json(
        body([row(barvlDt: '120', msg2: '[2]번째 전역', ordkey: '01002장암0')]),
      ),
      now: _received.add(const Duration(minutes: 5)),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.minutes, 0);
  });

  test('server clock ahead of the phone does not inflate minutes', () async {
    final source = build(
      (_) async => _json(
        body([row(barvlDt: '120', msg2: '[2]번째 전역', ordkey: '01002장암0')]),
      ),
      now: _received.subtract(const Duration(minutes: 3)),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.minutes, 2);
  });

  test('falls back to arvlMsg2 minutes', () async {
    final source = build(
      (_) async => _json(body([row(barvlDt: '0', msg2: '3분 20초 후 (보라매)')])),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.minutes, 4);
    expect(result.single.stationsAway, isNull);
  });

  test('arvlMsg2 without seconds uses exact minutes', () async {
    final source = build((_) async => _json(body([row(msg2: '5분 후 (상도)')])));

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.minutes, 5);
  });

  test('stations only gives null minutes', () async {
    final source = build(
      (_) async => _json(body([row(msg2: '[5]번째 전역 (상도)')])),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.minutes, isNull);
    expect(result.single.stationsAway, 5);
  });

  test('전역 도착 means one station away', () async {
    final source = build(
      (_) async => _json(body([row(msg2: '전역 도착', cd: '5')])),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.stationsAway, 1);
    expect(result.single.minutes, isNull);
  });

  test('당역 진입 means zero stations and arvlCd 1 means zero minutes', () async {
    final source = build(
      (_) async => _json(body([row(msg2: '당역 진입', cd: '1')])),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result.single.stationsAway, 0);
    expect(result.single.minutes, 0);
  });

  test('drops unparsable rows without throwing', () async {
    final source = build(
      (_) async => _json(
        jsonEncode({
          'errorMessage': {'code': 'INFO-000', 'message': 'ok'},
          'realtimeArrivalList': [
            'garbage',
            row(barvlDt: '120', ordkey: '01002장암0'),
          ],
        }),
      ),
    );

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result, hasLength(1));
  });

  test('unmapped line returns empty without calling', () async {
    var calls = 0;
    final source = build((_) async {
      calls++;
      return _json('{}');
    });

    final result = await source.arrivals(
      station: '장승배기',
      odsayLaneCode: 999,
      wayCode: 1,
    );

    expect(result, isEmpty);
    expect(calls, 0);
  });

  test('INFO-200 returns empty', () async {
    final source = build(
      (_) async => _json(_fixture('seoul_arrival_no_data.json')),
    );

    final result = await source.arrivals(
      station: '없는역',
      odsayLaneCode: 7,
      wayCode: 1,
    );

    expect(result, isEmpty);
  });

  test('bad key throws server with the message', () async {
    final source = build(
      (_) async => _json(_fixture('seoul_arrival_bad_key.json')),
    );

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(
        isA<CommuteServer>().having(
          (f) => f.message,
          'message',
          contains('인증키'),
        ),
      ),
    );
  });

  test('other error code inside errorMessage throws server', () async {
    final source = build(
      (_) async => _json(
        jsonEncode({
          'errorMessage': {
            'status': 500,
            'code': 'ERROR-300',
            'message': '필수 값이 누락되어 있습니다.',
          },
        }),
      ),
    );

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(
        isA<CommuteServer>().having(
          (f) => f.message,
          'message',
          '필수 값이 누락되어 있습니다.',
        ),
      ),
    );
  });

  test('non-JSON body throws server', () async {
    final source = build((_) async => http.Response('<html>', 502));

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(isA<CommuteServer>()),
    );
  });

  test('SocketException maps to network', () async {
    final source = build((_) async => throw const SocketException('down'));

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(isA<CommuteNetwork>()),
    );
  });

  test('HandshakeException maps to network', () async {
    final source = build((_) async => throw const HandshakeException('tls'));

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(isA<CommuteNetwork>()),
    );
  });

  test('5xx JSON without list or error throws server HTTP code', () async {
    final source = build(
      (_) async => http.Response.bytes(utf8.encode('{"status":500}'), 500),
    );

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(
        isA<CommuteServer>().having((f) => f.message, 'message', 'HTTP 500'),
      ),
    );
  });

  test('timeout maps to network', () async {
    final source = build(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1),
      throwsA(isA<CommuteNetwork>()),
    );
  });

  test('puts key in the path and encodes the station name', () async {
    late Uri requested;
    final source = build((request) async {
      requested = request.url;
      return _json(_fixture('seoul_arrival_no_data.json'));
    });

    await source.arrivals(station: '장승배기', odsayLaneCode: 7, wayCode: 1);

    expect(
      requested.toString(),
      'http://swopenapi.seoul.go.kr/api/subway/KEY123/json/realtimeStationArrival/0/20/'
      '${Uri.encodeComponent('장승배기')}',
    );
  });
}
