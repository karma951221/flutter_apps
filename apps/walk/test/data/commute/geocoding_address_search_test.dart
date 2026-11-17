import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:walk/data/commute/geocoding_address_search.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';

class _FakeNamer implements PlaceNamer {
  _FakeNamer(this.answer);

  final PlaceLookup Function(double lat, double lng) answer;

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) async => answer(lat, lng);
}

Location _loc(double lat, double lng) =>
    Location(latitude: lat, longitude: lng);

void main() {
  const locale = Locale('ko', 'KR');

  test('찾은 좌표에 이름을 붙이고 locale 을 넘긴다', () async {
    Locale? seen;
    String? asked;
    final search = GeocodingAddressSearch(
      _FakeNamer((lat, lng) => PlaceLookup.named('이름 $lat')),
      locations: (query, l) async {
        asked = query;
        seen = l;
        return [_loc(1, 2), _loc(3, 4)];
      },
      locale: () => locale,
    );

    final found = await search.search('강남역');

    expect(asked, '강남역');
    expect(seen, locale);
    expect(found, const [
      PlaceCandidate(lat: 1, lng: 2, label: '이름 1.0'),
      PlaceCandidate(lat: 3, lng: 4, label: '이름 3.0'),
    ]);
  });

  test('이름이 없거나 오프라인이면 검색어를 라벨로', () async {
    final search = GeocodingAddressSearch(
      _FakeNamer(
        (lat, lng) => lat == 1
            ? const PlaceLookup.noName()
            : const PlaceLookup.offline(),
      ),
      locations: (query, l) async => [_loc(1, 2), _loc(3, 4)],
    );

    final found = await search.search('세종대로 110');

    expect(found.map((c) => c.label), ['세종대로 110', '세종대로 110']);
  });

  test('최대 5개', () async {
    final search = GeocodingAddressSearch(
      _FakeNamer((lat, lng) => const PlaceLookup.noName()),
      locations: (query, l) async => [
        for (var i = 0; i < 8; i++) _loc(i.toDouble(), 0),
      ],
    );

    expect(await search.search('역'), hasLength(5));
  });

  test('예외 · 0건이면 빈 목록', () async {
    final namer = _FakeNamer((lat, lng) => const PlaceLookup.noName());

    final failing = GeocodingAddressSearch(
      namer,
      locations: (query, l) async => throw Exception('no result'),
    );
    final empty = GeocodingAddressSearch(
      namer,
      locations: (query, l) async => const [],
    );

    expect(await failing.search('없는 곳'), isEmpty);
    expect(await empty.search('없는 곳'), isEmpty);
  });

  test('시간 초과면 빈 목록', () async {
    final search = GeocodingAddressSearch(
      _FakeNamer((lat, lng) => const PlaceLookup.noName()),
      locations: (query, l) => Completer<List<Location>>().future,
      timeout: const Duration(milliseconds: 10),
    );

    expect(await search.search('강남역'), isEmpty);
  });

  test('빈 검색어는 묻지 않는다', () async {
    var calls = 0;
    final search = GeocodingAddressSearch(
      _FakeNamer((lat, lng) => const PlaceLookup.noName()),
      locations: (query, l) async {
        calls++;
        return [_loc(1, 2)];
      },
    );

    expect(await search.search(''), isEmpty);
    expect(await search.search('   '), isEmpty);
    expect(calls, 0);
  });
}
