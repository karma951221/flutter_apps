import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/commute/commute_policy.dart';
import 'package:walk/domain/commute/entity/catch_verdict.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/entity/train_arrival.dart';
import 'package:walk/domain/commute/entity/transit_route.dart';

TrainArrival t(int? minutes, {int? stationsAway}) => TrainArrival(
      minutes: minutes,
      estimated: false,
      stationsAway: stationsAway,
      message: '',
    );

SubwayLeg subway(int minutes, int stationCount) => RouteLeg.subway(
      minutes: minutes,
      lineName: '9호선',
      odsayLaneCode: 109,
      startStation: 'a',
      endStation: 'b',
      wayCode: 1,
      wayName: 'x',
      stationCount: stationCount,
    ) as SubwayLeg;

TransitRoute sampleRoute() => TransitRoute(
      totalMinutes: 41,
      transferCount: 1,
      legs: [
        const RouteLeg.walk(minutes: 6),
        subway(16, 8),
        const RouteLeg.walk(minutes: 3),
        subway(2, 1),
        const RouteLeg.walk(minutes: 7),
      ],
    );

void main() {
  group('judgeCatch', () {
    test('boundary catchFirst', () {
      expect(judgeCatch([t(7), t(14)], 6), const CatchVerdict.catchFirst());
    });
    test('catchSecond', () {
      expect(judgeCatch([t(6), t(14)], 6), const CatchVerdict.catchSecond());
    });
    test('missBoth', () {
      expect(judgeCatch([t(3), t(5)], 6), const CatchVerdict.missBoth());
    });
    test('skips null minutes', () {
      expect(judgeCatch([t(null), t(9)], 6), const CatchVerdict.catchFirst());
    });
    test('unknown', () {
      expect(judgeCatch([], 6), const CatchVerdict.unknown());
      expect(judgeCatch([t(null)], 6), const CatchVerdict.unknown());
    });
    test('zero walk', () {
      expect(judgeCatch([t(1)], 0), const CatchVerdict.catchFirst());
      expect(judgeCatch([t(0)], 0), const CatchVerdict.missBoth());
    });
  });

  group('boardingTrain', () {
    test('picks by verdict', () {
      final a = [t(null), t(7), t(14)];
      expect(boardingTrain(a, const CatchVerdict.catchFirst()), a[1]);
      expect(boardingTrain(a, const CatchVerdict.catchSecond()), a[2]);
      expect(boardingTrain(a, const CatchVerdict.missBoth()), a[2]);
      expect(boardingTrain(a, const CatchVerdict.unknown()), isNull);
    });
  });

  group('estimateEta', () {
    final now = DateTime(2026, 10, 21, 8, 0);
    test('with boarding', () {
      expect(
        estimateEta(now: now, route: sampleRoute(), boarding: t(7)),
        DateTime(2026, 10, 21, 8, 35),
      );
    });
    test('without boarding', () {
      expect(
        estimateEta(now: now, route: sampleRoute()),
        DateTime(2026, 10, 21, 8, 41),
      );
    });
  });

  group('withEstimatedMinutes', () {
    test('estimates', () {
      final r = withEstimatedMinutes(t(null, stationsAway: 3), subway(16, 8));
      expect(r.minutes, 6);
      expect(r.estimated, isTrue);
    });
    test('rounds up', () {
      expect(
        withEstimatedMinutes(t(null, stationsAway: 3), subway(10, 4)).minutes,
        8,
      );
    });
    test('keeps existing minutes', () {
      final r = withEstimatedMinutes(t(4, stationsAway: 3), subway(16, 8));
      expect(r.minutes, 4);
      expect(r.estimated, isFalse);
    });
    test('keeps when no stationsAway or stationCount 0', () {
      expect(withEstimatedMinutes(t(null), subway(16, 8)).minutes, isNull);
      expect(
        withEstimatedMinutes(t(null, stationsAway: 3), subway(16, 0)).minutes,
        isNull,
      );
    });
  });

  test('defaultAt', () {
    expect(CommuteDirection.defaultAt(DateTime(2026, 1, 1, 11, 59)),
        CommuteDirection.toWork);
    expect(CommuteDirection.defaultAt(DateTime(2026, 1, 1, 12, 0)),
        CommuteDirection.toHome);
  });

  test('isStale', () {
    final q = DateTime(2026, 1, 1, 8, 0, 0);
    expect(isStale(q, DateTime(2026, 1, 1, 8, 1, 59)), isFalse);
    expect(isStale(q, DateTime(2026, 1, 1, 8, 2, 0)), isTrue);
  });
}
