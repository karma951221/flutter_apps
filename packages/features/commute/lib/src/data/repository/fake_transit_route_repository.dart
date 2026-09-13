import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entity/geo_point.dart';
import '../../domain/entity/transit_leg.dart';
import '../../domain/entity/transit_leg_kind.dart';
import '../../domain/entity/transit_mode.dart';
import '../../domain/entity/transit_route.dart';
import '../../domain/repository/transit_route_repository.dart';

@LazySingleton(as: TransitRouteRepository)
class FakeTransitRouteRepository implements TransitRouteRepository {
  @override
  Future<Result<List<TransitRoute>>> search({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    final distance = _haversineKm(origin, destination);
    return Ok([
      _subwayRoute(distance),
      _busRoute(distance),
      _bestRoute(distance),
    ]);
  }

  TransitRoute _subwayRoute(double distance) {
    final minutes = (8 + 3 * distance).round();
    final transfers = distance < 4
        ? 0
        : distance < 10
        ? 1
        : 2;
    final transitMinutes = minutes - 8;
    final segmentMinutes = _split(transitMinutes, transfers + 1);
    const labels = ['2호선', '9호선', '7호선'];
    return TransitRoute(
      mode: TransitMode.subway,
      duration: Duration(minutes: minutes),
      transferCount: transfers,
      legs: [
        const TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 4),
        for (var i = 0; i < segmentMinutes.length; i++)
          TransitLeg(
            kind: TransitLegKind.subway,
            label: labels[i],
            minutes: segmentMinutes[i],
          ),
        const TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 4),
      ],
    );
  }

  TransitRoute _busRoute(double distance) {
    final minutes = (5 + 4.5 * distance).round();
    final transfers = distance < 6 ? 0 : 1;
    final transitMinutes = minutes - 6;
    final segmentMinutes = _split(transitMinutes, transfers + 1);
    const labels = ['146번', '360번'];
    return TransitRoute(
      mode: TransitMode.bus,
      duration: Duration(minutes: minutes),
      transferCount: transfers,
      legs: [
        const TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
        for (var i = 0; i < segmentMinutes.length; i++)
          TransitLeg(
            kind: TransitLegKind.bus,
            label: labels[i],
            minutes: segmentMinutes[i],
          ),
        const TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
      ],
    );
  }

  TransitRoute _bestRoute(double distance) {
    final minutes = (6 + 2.7 * distance).round();
    final transitMinutes = minutes - 6;
    final middle = _split(transitMinutes, 2);
    return TransitRoute(
      mode: TransitMode.best,
      duration: Duration(minutes: minutes),
      transferCount: 1,
      legs: [
        const TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
        TransitLeg(kind: TransitLegKind.bus, label: '146번', minutes: middle[0]),
        TransitLeg(
          kind: TransitLegKind.subway,
          label: '9호선',
          minutes: middle[1],
        ),
        const TransitLeg(kind: TransitLegKind.walk, label: '도보', minutes: 3),
      ],
    );
  }

  List<int> _split(int total, int count) => [
    for (var i = 0; i < count; i++)
      total ~/ count + (i < total.remainder(count) ? 1 : 0),
  ];

  double _haversineKm(GeoPoint from, GeoPoint to) {
    const earthRadiusKm = 6371.0;
    final latDelta = _radians(to.lat - from.lat);
    final lngDelta = _radians(to.lng - from.lng);
    final a =
        math.pow(math.sin(latDelta / 2), 2) +
        math.cos(_radians(from.lat)) *
            math.cos(_radians(to.lat)) *
            math.pow(math.sin(lngDelta / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
