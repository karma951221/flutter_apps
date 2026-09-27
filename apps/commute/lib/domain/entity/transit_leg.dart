import 'package:freezed_annotation/freezed_annotation.dart';

import 'transit_leg_kind.dart';

part 'transit_leg.freezed.dart';

@freezed
class TransitLeg with _$TransitLeg {
  @override
  final TransitLegKind kind;
  @override
  final String label;
  @override
  final int minutes;

  const TransitLeg({
    required this.kind,
    required this.label,
    required this.minutes,
  });
}
