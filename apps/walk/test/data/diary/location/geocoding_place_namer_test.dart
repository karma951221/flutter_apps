import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:walk/data/diary/location/geocoding_place_namer.dart';

void main() {
  group('composePlaceName', () {
    test('locality · subLocality · thoroughfare 중 비지 않은 앞의 두 개를 공백으로', () {
      expect(
        composePlaceName(
          const Placemark(
            locality: '제주시',
            subLocality: '애월읍',
            thoroughfare: '애월로',
          ),
        ),
        '제주시 애월읍',
      );
    });

    test('빈 값 · 공백은 건너뛴다', () {
      expect(
        composePlaceName(
          const Placemark(locality: ' ', subLocality: null, thoroughfare: '애월로'),
        ),
        '애월로',
      );
      expect(
        composePlaceName(
          const Placemark(locality: '서울', subLocality: '', thoroughfare: '세종대로'),
        ),
        '서울 세종대로',
      );
    });

    test('하나뿐이면 그것만, 없으면 null', () {
      expect(composePlaceName(const Placemark(locality: '서울')), '서울');
      expect(composePlaceName(const Placemark()), isNull);
    });
  });

  group('GeocodingPlaceNamer', () {
    const locale = Locale('ko', 'KR');

    test('호출마다 locale 을 넘기고 이름을 조합한다', () async {
      Locale? seen;
      final namer = GeocodingPlaceNamer(
        placemarks: (lat, lng, l) async {
          seen = l;
          return [const Placemark(locality: '서울', subLocality: '중구')];
        },
        locale: () => locale,
      );

      expect(await namer.nameFor(37.5, 127), '서울 중구');
      expect(seen, locale);
    });

    test('첫 결과에 이름이 없으면 다음 결과를 쓴다', () async {
      final namer = GeocodingPlaceNamer(
        placemarks: (_, _, _) async => [
          const Placemark(),
          const Placemark(locality: '서울'),
        ],
        locale: () => locale,
      );

      expect(await namer.nameFor(1, 2), '서울');
    });

    test('빈 목록 → null', () async {
      final namer = GeocodingPlaceNamer(
        placemarks: (_, _, _) async => const [],
        locale: () => locale,
      );

      expect(await namer.nameFor(1, 2), isNull);
    });

    test('예외 → null', () async {
      final namer = GeocodingPlaceNamer(
        placemarks: (_, _, _) async => throw Exception('no network'),
        locale: () => locale,
      );

      expect(await namer.nameFor(1, 2), isNull);
    });

    test('응답이 끝나지 않으면 타임아웃 뒤 null', () async {
      final namer = GeocodingPlaceNamer(
        placemarks: (_, _, _) => Completer<List<Placemark>>().future,
        locale: () => locale,
        timeout: const Duration(milliseconds: 50),
      );

      expect(await namer.nameFor(1, 2), isNull);
    });
  });
}
