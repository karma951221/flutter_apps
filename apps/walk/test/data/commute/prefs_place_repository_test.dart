import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/commute/prefs_place_repository.dart';
import 'package:walk/domain/commute/entity/place.dart';

void main() {
  const home = Place(kind: PlaceKind.home, lat: 37.5, lng: 127.0, label: '집');
  const work = Place(kind: PlaceKind.work, lat: 37.4, lng: 127.1, label: '회사');

  test('저장한 적이 없으면 null', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsPlaceRepository(await SharedPreferences.getInstance());

    expect(repo.load(PlaceKind.home), isNull);
    expect(repo.load(PlaceKind.work), isNull);
  });

  test('집 · 회사를 따로 저장하고 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await PrefsPlaceRepository(prefs).save(home);
    await PrefsPlaceRepository(prefs).save(work);

    final repo = PrefsPlaceRepository(prefs);
    expect(repo.load(PlaceKind.home), home);
    expect(repo.load(PlaceKind.work), work);
    expect(prefs.get(PrefsPlaceRepository.homeKey), isA<String>());
    expect(prefs.get(PrefsPlaceRepository.workKey), isA<String>());
  });

  test('깨진 값이면 null', () async {
    SharedPreferences.setMockInitialValues({
      PrefsPlaceRepository.homeKey: '{not json',
      PrefsPlaceRepository.workKey: 42,
    });
    final repo = PrefsPlaceRepository(await SharedPreferences.getInstance());

    expect(repo.load(PlaceKind.home), isNull);
    expect(repo.load(PlaceKind.work), isNull);
  });

  test('다른 칸에 들어 있는 장소는 읽지 않는다', () async {
    SharedPreferences.setMockInitialValues({
      PrefsPlaceRepository.homeKey:
          '{"kind":"work","lat":1,"lng":2,"label":"회사"}',
    });
    final repo = PrefsPlaceRepository(await SharedPreferences.getInstance());

    expect(repo.load(PlaceKind.home), isNull);
  });

  test('키 이름', () {
    expect(PrefsPlaceRepository.homeKey, 'commute.place.home');
    expect(PrefsPlaceRepository.workKey, 'commute.place.work');
  });
}
