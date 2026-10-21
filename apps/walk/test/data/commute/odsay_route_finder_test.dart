import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walk/core/config/commute_api_keys.dart';
import 'package:walk/data/commute/odsay_route_finder.dart';
import 'package:walk/domain/commute/commute_failure.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';

String _fixture(String name) => File('test/fixtures/commute/$name').readAsStringSync();

http.Response _json(String body) =>
    http.Response.bytes(utf8.encode(body), 200, headers: {'content-type': 'application/json'});

const _home = Place(kind: PlaceKind.home, lat: 37.5, lng: 126.93, label: '집');
const _work = Place(kind: PlaceKind.work, lat: 37.49, lng: 127.03, label: '회사');

void main() {
  const keys = CommuteApiKeys(odsay: 'a+b/c=', seoulSubway: 's');

  OdsayRouteFinder build(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 10),
  }) =>
      OdsayRouteFinder(MockClient(handler), keys, timeout: timeout);

  Future<void> expectFailure(Future<Object?> future, Matcher matcher) async {
    await expectLater(future, throwsA(matcher));
  }

  test('parses subway path legs', () async {
    final finder = build((_) async => _json(_fixture('odsay_home_to_work.json')));
    final routes = await finder.find(from: _home, to: _work);

    expect(routes, hasLength(2));
    final first = routes.first;
    expect(first.totalMinutes, 41);
    expect(first.transferCount, 1);
    expect(first.legs, hasLength(5));
    expect(first.legs[0], const RouteLeg.walk(minutes: 6));
    expect(
      first.legs[1],
      const RouteLeg.subway(
        minutes: 16,
        lineName: '수도권 7호선',
        odsayLaneCode: 7,
        startStation: '장승배기',
        endStation: '논현',
        wayCode: 1,
        wayName: '도봉산',
        stationCount: 8,
      ),
    );
    expect(first.legs[2], const RouteLeg.walk(minutes: 3));
    expect(
      first.legs[3],
      const RouteLeg.subway(
        minutes: 2,
        lineName: '수도권 신분당선',
        odsayLaneCode: 109,
        startStation: '신논현',
        endStation: '강남',
        wayCode: 2,
        wayName: '강남',
        stationCount: 1,
      ),
    );
    expect(first.legs[4], const RouteLeg.walk(minutes: 7));

    final second = routes[1];
    expect(second.totalMinutes, 45);
    expect(second.transferCount, 0);
    expect(second.legs.first, const RouteLeg.walk(minutes: 0));
  });

  test('drops paths with bus legs', () async {
    final body = jsonEncode({
      'result': {
        'path': [
          {
            'info': {'totalTime': 30},
            'subPath': [
              {'trafficType': 2, 'sectionTime': 10},
            ],
          },
          jsonDecode(_fixture('odsay_home_to_work.json'))['result']['path'][1],
        ],
      },
    });
    final routes = await build((_) async => _json(body)).find(from: _home, to: _work);
    expect(routes, hasLength(1));
    expect(routes.single.totalMinutes, 45);
  });

  test('all paths with bus legs → noRoute', () async {
    final body = jsonEncode({
      'result': {
        'path': [
          {
            'info': {'totalTime': 30},
            'subPath': [
              {'trafficType': 2, 'sectionTime': 10},
            ],
          },
        ],
      },
    });
    await expectFailure(
      build((_) async => _json(body)).find(from: _home, to: _work),
      isA<CommuteNoRoute>(),
    );
  });

  group('error body maps to noRoute/server', () {
    test('close distance object → noRoute', () async {
      await expectFailure(
        build((_) async => _json(_fixture('odsay_error_close.json'))).find(from: _home, to: _work),
        isA<CommuteNoRoute>(),
      );
    });

    test('key error array → server message', () async {
      await expectFailure(
        build((_) async => _json(_fixture('odsay_error_key.json'))).find(from: _home, to: _work),
        isA<CommuteServer>().having((e) => e.message, 'message', 'ApiKeyAuthFailed'),
      );
    });

    for (final code in ['-99', '3', '4', '5', '6']) {
      test('code $code → noRoute', () async {
        final body = jsonEncode({
          'error': {'code': code, 'msg': 'x'},
        });
        await expectFailure(
          build((_) async => _json(body)).find(from: _home, to: _work),
          isA<CommuteNoRoute>(),
        );
      });
    }

    test('object error with msg → server msg', () async {
      final body = jsonEncode({
        'error': {'code': '-8', 'msg': 'bad'},
      });
      await expectFailure(
        build((_) async => _json(body)).find(from: _home, to: _work),
        isA<CommuteServer>().having((e) => e.message, 'message', 'bad'),
      );
    });
  });

  test('empty path → noRoute', () async {
    await expectFailure(
      build((_) async => _json('{"result":{"path":[]}}')).find(from: _home, to: _work),
      isA<CommuteNoRoute>(),
    );
  });

  test('non-json body → server', () async {
    await expectFailure(
      build((_) async => http.Response('<html>', 502)).find(from: _home, to: _work),
      isA<CommuteServer>(),
    );
  });

  test('query uses SX=lng SY=lat order and encodes key', () async {
    late Uri uri;
    final finder = build((request) async {
      uri = request.url;
      return _json(_fixture('odsay_home_to_work.json'));
    });
    await finder.find(from: _home, to: _work);

    expect(uri.host, 'api.odsay.com');
    expect(uri.path, '/v1/api/searchPubTransPathT');
    expect(uri.queryParameters['SX'], '126.93');
    expect(uri.queryParameters['SY'], '37.5');
    expect(uri.queryParameters['EX'], '127.03');
    expect(uri.queryParameters['EY'], '37.49');
    expect(uri.queryParameters['SearchPathType'], '1');
    expect(uri.queryParameters['apiKey'], 'a+b/c=');
    expect(uri.query, contains('apiKey=a%2Bb%2Fc%3D'));
  });

  test('timeout → network', () async {
    final finder = build(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 10),
    );
    await expectFailure(finder.find(from: _home, to: _work), isA<CommuteNetwork>());
  });

  test('socket error → network', () async {
    final finder = build((_) async => throw const SocketException('down'));
    await expectFailure(finder.find(from: _home, to: _work), isA<CommuteNetwork>());
  });
}
