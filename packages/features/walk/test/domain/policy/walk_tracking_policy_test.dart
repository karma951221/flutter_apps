import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const policy = WalkTrackingPolicy();
  final previous = trackPoint(37);

  test('정확도 50m 초과 점을 버린다', () {
    expect(
      policy.accept(
        previous: previous,
        next: trackPoint(37.1, accuracy: 50.1),
        stepMeters: 100,
      ),
      isFalse,
    );
  });

  test('2m 미만 이동은 버린다', () {
    expect(
      policy.accept(
        previous: previous,
        next: trackPoint(37.00001, accuracy: 5),
        stepMeters: 1.9,
      ),
      isFalse,
    );
  });

  test('첫 점은 항상 받는다', () {
    expect(
      policy.accept(
        previous: null,
        next: trackPoint(37, accuracy: 50),
        stepMeters: 0,
      ),
      isTrue,
    );
  });

  test('정확도가 없는 점은 거리로만 판단한다', () {
    expect(
      policy.accept(previous: previous, next: trackPoint(37.1), stepMeters: 2),
      isTrue,
    );
    expect(
      policy.accept(previous: previous, next: trackPoint(37.1), stepMeters: 1),
      isFalse,
    );
  });
}
