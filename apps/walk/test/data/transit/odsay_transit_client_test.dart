import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/data/transit/odsay_transit_client.dart';
import 'package:walk/domain/transit/entity/station_hit.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/domain/transit/entity/transit_point.dart';
import 'package:walk/domain/transit/transit_failure.dart';

String _fixture(String name) =>
    File('test/fixtures/transit/$name').readAsStringSync();

http.Response _json(String body, [int status = 200]) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _from = TransitPoint(
  lat: 37.5,
  lng: 126.93,
  label: '집',
  source: TransitPointSource.home,
);
const _to = TransitPoint(
  lat: 37.49,
  lng: 127.03,
  label: '회사',
  source: TransitPointSource.work,
);

void main() {
  OdsayTransitClient build(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 10),
  }) => OdsayTransitClient(MockClient(handler), timeout: timeout);

  Future<List<TransitPath>> find(OdsayTransitClient c) =>
      c.find(from: _from, to: _to, apiKey: 'k');

  Future<void> expectFind(
    Future<http.Response> Function(http.Request) handler,
    Matcher failure,
  ) => expectLater(find(build(handler)), throwsA(failure));

  test('parses mixed path into walk/subway/bus legs', () async {
    final paths = await find(
      build((_) async => _json(_fixture('odsay_path_mixed.json'))),
    );
    expect(paths, hasLength(1));
    final p = paths.single;
    expect(p.totalMinutes, 52);
    expect(p.fare, 2150);
    expect(p.legs, hasLength(5));
    expect(p.legs[0], const TransitLeg.walk(minutes: 4, distanceM: 300));
    expect(
      p.legs[1],
      const TransitLeg.subway(
        minutes: 20,
        lineName: '수도권 2호선',
        subwayCode: 2,
        start: '강남',
        end: '사당',
        stationCount: 7,
        way: '신도림',
      ),
    );
    expect(
      p.legs[3],
      const TransitLeg.bus(
        minutes: 18,
        busNumbers: ['5412', '6411'],
        start: '사당역',
        end: '봉천동',
        stationCount: 9,
      ),
    );
    expect(p.walkMinutes, 14);
  });

  test('transferCount counts non-walk legs minus one', () async {
    final mixed = await find(
      build((_) async => _json(_fixture('odsay_path_mixed.json'))),
    );
    expect(mixed.single.transferCount, 1);
    final bus = await find(
      build((_) async => _json(_fixture('odsay_path_bus_only.json'))),
    );
    expect(bus.single.transferCount, 0);
  });

  test('fare null when payment missing', () async {
    final paths = await find(
      build((_) async => _json(_fixture('odsay_path_bus_only.json'))),
    );
    expect(paths.single.fare, isNull);
  });

  test('key error with 200 is keyRejected', () async {
    await expectFind(
      (_) async => _json(_fixture('odsay_error_key.json')),
      isA<TransitKeyRejected>().having(
        (f) => f.message,
        'message',
        'ApiKeyAuthFailed',
      ),
    );
  });

  test('-98 is tooClose', () async {
    await expectFind(
      (_) async => _json(_fixture('odsay_error_close.json')),
      isA<TransitTooClose>(),
    );
  });

  test('-99 is noRoute', () async {
    await expectFind(
      (_) async => _json(_fixture('odsay_error_no_route.json')),
      isA<TransitNoRoute>(),
    );
  });

  test('quota message is quotaExceeded', () async {
    await expectFind(
      (_) async => _json(_fixture('odsay_error_quota.json')),
      isA<TransitQuotaExceeded>(),
    );
  });

  test('unknown error is server(msg)', () async {
    await expectFind(
      (_) async => _json('{"error": {"code": "-1", "msg": "boom"}}'),
      isA<TransitServer>().having((f) => f.message, 'message', 'boom'),
    );
  });

  test('socket/timeout/TLS → network', () async {
    await expectFind(
      (_) async => throw const SocketException('x'),
      isA<TransitNetwork>(),
    );
    await expectFind(
      (_) async => throw const HandshakeException('x'),
      isA<TransitNetwork>(),
    );
    await expectFind(
      (_) async => throw http.ClientException('x'),
      isA<TransitNetwork>(),
    );
    await expectLater(
      find(
        build(
          (_) => Completer<http.Response>().future,
          timeout: const Duration(milliseconds: 10),
        ),
      ),
      throwsA(isA<TransitNetwork>()),
    );
  });

  test('non-2xx without error body → server(HTTP 503)', () async {
    await expectFind(
      (_) async => http.Response('oops', 503),
      isA<TransitServer>().having((f) => f.message, 'message', 'HTTP 503'),
    );
  });

  test('all paths unparsable → server(parse)', () async {
    await expectFind(
      (_) async => _json('{"result": {"path": [{"info": 1}, 5]}}'),
      isA<TransitServer>().having((f) => f.message, 'message', 'parse'),
    );
  });

  test('apiKey is url-encoded in query', () async {
    late Uri uri;
    final client = build((req) async {
      uri = req.url;
      return _json(_fixture('odsay_path_mixed.json'));
    });
    await client.find(from: _from, to: _to, apiKey: 'a+b/c=');
    expect(uri.host, 'api.odsay.com');
    expect(uri.path, '/v1/api/searchPubTransPathT');
    expect(uri.toString(), contains('apiKey=a%2Bb%2Fc%3D'));
    expect(uri.queryParameters['apiKey'], 'a+b/c=');
    expect(uri.queryParameters['SX'], '126.93');
    expect(uri.queryParameters['SY'], '37.5');
    expect(uri.queryParameters['EX'], '127.03');
    expect(uri.queryParameters['EY'], '37.49');
    expect(uri.queryParameters['SearchPathType'], '0');
  });

  group('station search', () {
    test('maps class 2 to subway first and caps 20', () async {
      late Uri uri;
      final client = build((req) async {
        uri = req.url;
        return _json(_fixture('odsay_station.json'));
      });
      final hits = await client.search('강남', apiKey: 'a+b');
      expect(uri.path, '/v1/api/searchStation');
      expect(uri.queryParameters['stationName'], '강남');
      expect(uri.queryParameters['stationClass'], '1,2');
      expect(uri.toString(), contains('apiKey=a%2Bb'));
      expect(hits.map((h) => h.kind), [
        StationKind.subway,
        StationKind.subway,
        StationKind.bus,
        StationKind.bus,
      ]);
      expect(
        hits.first,
        const StationHit(
          name: '강남',
          kind: StationKind.subway,
          lat: 37.4979,
          lng: 127.0276,
          detail: '수도권 2호선',
        ),
      );
      expect(hits[2].detail, '22009 · 서초구');

      final many = jsonEncode({
        'result': {
          'station': [
            for (var i = 0; i < 30; i++)
              {
                'stationClass': i.isEven ? 1 : 2,
                'stationName': 's$i',
                'x': 127.0,
                'y': 37.0,
                'laneName': 'L',
                'arsID': '1',
                'gu': 'g',
              },
          ],
        },
      });
      final capped = await build(
        (_) async => _json(many),
      ).search('s', apiKey: 'k');
      expect(capped, hasLength(20));
      expect(capped.first.kind, StationKind.subway);
    });

    test('no result → empty list, error → failure', () async {
      final empty = await build(
        (_) async => _json(_fixture('odsay_error_no_route.json')),
      ).search('zz', apiKey: 'k');
      expect(empty, isEmpty);
      await expectLater(
        build(
          (_) async => _json(_fixture('odsay_error_key.json')),
        ).search('zz', apiKey: 'k'),
        throwsA(isA<TransitKeyRejected>()),
      );
    });
  });
}
