import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/diary/draft/photo_meta.dart';
import 'package:walk/domain/diary/draft/photo_place_names.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';

class _Namer implements PlaceNamer {
  _Namer(this.answer);

  final PlaceLookup Function(double lat, double lng) answer;
  final calls = <(double, double)>[];

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) async {
    calls.add((lat, lng));
    return answer(lat, lng);
  }
}

void main() {
  test('좌표마다 이름을 구하고 같은 이름은 한 번만(순서 유지)', () async {
    final namer = _Namer(
      (lat, _) => PlaceLookup.named(lat < 37.55 ? '성수동' : '뚝섬'),
    );

    final names = await PhotoPlaceNames(namer).namesFor([
      const PhotoMeta(lat: 37.544, lng: 127.05),
      const PhotoMeta(lat: 37.545, lng: 127.06),
      const PhotoMeta(lat: 37.531, lng: 127.067),
      const PhotoMeta(lat: 37.6, lng: 127.07),
    ]);

    expect(names, ['성수동', '뚝섬']);
  });

  test('좌표 없는 사진 · null 은 묻지 않는다', () async {
    final namer = _Namer((_, _) => const PlaceLookup.named('x'));

    final names = await PhotoPlaceNames(
      namer,
    ).namesFor([null, PhotoMeta(takenAt: DateTime(2026)), const PhotoMeta()]);

    expect(names, isEmpty);
    expect(namer.calls, isEmpty);
  });

  test('100m 안쪽(소수 셋째 자리까지 같은) 좌표는 한 번만 묻는다', () async {
    final namer = _Namer((_, _) => const PlaceLookup.named('성수동'));

    await PhotoPlaceNames(namer).namesFor([
      const PhotoMeta(lat: 37.54401, lng: 127.05001),
      const PhotoMeta(lat: 37.54402, lng: 127.05002),
    ]);

    expect(namer.calls, hasLength(1));
  });

  test('이름 없음 · 오프라인 · 예외는 빼고 나머지만', () async {
    final namer = _Namer(
      (lat, _) => switch (lat) {
        1 => const PlaceLookup.noName(),
        2 => const PlaceLookup.offline(),
        3 => throw StateError('boom'),
        _ => const PlaceLookup.named('뚝섬'),
      },
    );

    final names = await PhotoPlaceNames(namer).namesFor([
      const PhotoMeta(lat: 1, lng: 1),
      const PhotoMeta(lat: 2, lng: 2),
      const PhotoMeta(lat: 3, lng: 3),
      const PhotoMeta(lat: 4, lng: 4),
    ]);

    expect(names, ['뚝섬']);
  });

  test('서로 다른 좌표는 최대 maxLookups 번만 묻는다', () async {
    final namer = _Namer((lat, _) => PlaceLookup.named('곳$lat'));

    await PhotoPlaceNames(namer).namesFor([
      for (var i = 0; i < PhotoPlaceNames.maxLookups + 3; i++)
        PhotoMeta(lat: i.toDouble(), lng: 0),
    ]);

    expect(namer.calls, hasLength(PhotoPlaceNames.maxLookups));
  });
}
