import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/commute/prefs_route_preference_repository.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';

void main() {
  test('저장한 적이 없으면 null', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsRoutePreferenceRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repo.load(CommuteDirection.toWork), isNull);
    expect(repo.load(CommuteDirection.toHome), isNull);
  });

  test('방향별로 서명을 따로 저장한다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await PrefsRoutePreferenceRepository(prefs)
        .save(CommuteDirection.toWork, '2:강남>역삼');
    await PrefsRoutePreferenceRepository(prefs)
        .save(CommuteDirection.toHome, '2:역삼>강남');

    final repo = PrefsRoutePreferenceRepository(prefs);
    expect(repo.load(CommuteDirection.toWork), '2:강남>역삼');
    expect(repo.load(CommuteDirection.toHome), '2:역삼>강남');
    expect(prefs.get('commute.route.toWork'), '2:강남>역삼');
    expect(prefs.get('commute.route.toHome'), '2:역삼>강남');
  });

  test('문자열이 아니면 null', () async {
    SharedPreferences.setMockInitialValues({'commute.route.toWork': 3});
    final repo = PrefsRoutePreferenceRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repo.load(CommuteDirection.toWork), isNull);
  });
}
