import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/entity/transit_path.dart';
import 'package:walk/domain/transit/transit_sort.dart';

TransitPath _path(int total, int transfers, int walk) => TransitPath(
  totalMinutes: total,
  transferCount: transfers,
  legs: [TransitLeg.walk(minutes: walk, distanceM: walk * 80)],
);

void main() {
  test('sortTransitPaths orders by total then transfers then walk', () {
    final sorted = sortTransitPaths([
      _path(42, 1, 9),
      _path(42, 0, 14),
      _path(47, 0, 3),
      _path(42, 0, 9),
    ]);
    expect(
      sorted.map((p) => (p.totalMinutes, p.transferCount, p.walkMinutes)),
      [(42, 0, 9), (42, 0, 14), (42, 1, 9), (47, 0, 3)],
    );
  });
}
