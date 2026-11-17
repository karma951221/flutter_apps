import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';

void main() {
  test('walkMinutes sums walk legs only', () {
    const path = TransitPath(
      totalMinutes: 20,
      transferCount: 0,
      legs: [
        TransitLeg.walk(minutes: 5, distanceM: 300),
        TransitLeg.subway(
          minutes: 12,
          lineName: '2호선',
          subwayCode: 2,
          start: '강남',
          end: '역삼',
          stationCount: 1,
          way: '내선',
        ),
        TransitLeg.walk(minutes: 3, distanceM: 200),
      ],
    );
    expect(path.walkMinutes, 8);
  });
}
