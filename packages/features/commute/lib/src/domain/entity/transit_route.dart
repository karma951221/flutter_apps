import 'package:freezed_annotation/freezed_annotation.dart';

import 'transit_leg.dart';
import 'transit_mode.dart';

part 'transit_route.freezed.dart';

@freezed
class TransitRoute with _$TransitRoute {
  @override
  final TransitMode mode;
  @override
  final Duration duration;
  @override
  final int transferCount;
  @override
  final List<TransitLeg> legs;

  const TransitRoute({
    required this.mode,
    required this.duration,
    required this.transferCount,
    required this.legs,
  });
}
