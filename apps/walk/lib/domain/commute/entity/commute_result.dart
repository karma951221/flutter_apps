import 'package:freezed_annotation/freezed_annotation.dart';

import 'catch_verdict.dart';
import 'commute_direction.dart';
import 'train_arrival.dart';
import 'transit_route.dart';

part 'commute_result.freezed.dart';

enum RealtimeStatus { ok, unavailable, failed }

@freezed
class CommuteResult with _$CommuteResult {
  @override
  final CommuteDirection direction;

  @override
  final TransitRoute route;

  @override
  final List<TransitRoute> alternatives;

  @override
  final List<TrainArrival> arrivals;

  @override
  final RealtimeStatus realtime;

  @override
  final CatchVerdict verdict;

  @override
  final DateTime eta;

  /// 도착 예상에 실시간 열차를 썼는지.
  @override
  final bool etaFromRealtime;

  @override
  final DateTime queriedAt;

  const CommuteResult({
    required this.direction,
    required this.route,
    required this.alternatives,
    required this.arrivals,
    required this.realtime,
    required this.verdict,
    required this.eta,
    required this.etaFromRealtime,
    required this.queriedAt,
  });
}
