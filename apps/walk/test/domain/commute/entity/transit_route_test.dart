import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';

RouteLeg sub(int minutes, int lane, String from, String to) => RouteLeg.subway(
      minutes: minutes,
      lineName: 'L',
      odsayLaneCode: lane,
      startStation: from,
      endStation: to,
      wayCode: 1,
      wayName: 'w',
      stationCount: 3,
    );

void main() {
  final route = TransitRoute(
    totalMinutes: 41,
    transferCount: 1,
    legs: [
      const RouteLeg.walk(minutes: 6),
      sub(16, 7, '장승배기', '논현'),
      const RouteLeg.walk(minutes: 3),
      sub(2, 109, '신논현', '강남'),
      const RouteLeg.walk(minutes: 7),
    ],
  );

  test('derived values', () {
    expect(route.walkToStationMinutes, 6);
    expect(route.minutesFromBoarding, 28);
    expect(route.signature, '7:장승배기>논현|109:신논현>강남');
    expect(route.firstSubway?.startStation, '장승배기');
  });

  test('no subway', () {
    const r = TransitRoute(
      totalMinutes: 20,
      transferCount: 0,
      legs: [RouteLeg.walk(minutes: 12), RouteLeg.walk(minutes: 8)],
    );
    expect(r.firstSubway, isNull);
    expect(r.walkToStationMinutes, 20);
  });

  test('Place json', () {
    const p = Place(kind: PlaceKind.home, lat: 37.5, lng: 127.0, label: '집');
    expect(Place.fromJson(p.toJson()), p);
    expect(Place.fromJson('x'), isNull);
    expect(Place.fromJson({'kind': 'home', 'lat': 1.0}), isNull);
    expect(Place.fromJson({'kind': 'zzz', 'lat': 1.0, 'lng': 2.0, 'label': 'a'}),
        isNull);
  });

  test('direction origin/destination', () {
    expect(CommuteDirection.toWork.origin, PlaceKind.home);
    expect(CommuteDirection.toWork.destination, PlaceKind.work);
    expect(CommuteDirection.toHome.origin, PlaceKind.work);
  });
}
