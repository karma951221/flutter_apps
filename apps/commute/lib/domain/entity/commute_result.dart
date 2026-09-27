import 'package:freezed_annotation/freezed_annotation.dart';

import 'commute_direction.dart';
import 'origin.dart';
import 'station.dart';
import 'transit_route.dart';

part 'commute_result.freezed.dart';

@freezed
class CommuteResult with _$CommuteResult {
  @override
  final CommuteDirection direction;
  @override
  final Origin origin;
  @override
  final Station destination;
  @override
  final List<TransitRoute> routes;
  @override
  final DateTime searchedAt;

  const CommuteResult({
    required this.direction,
    required this.origin,
    required this.destination,
    required this.routes,
    required this.searchedAt,
  });
}
