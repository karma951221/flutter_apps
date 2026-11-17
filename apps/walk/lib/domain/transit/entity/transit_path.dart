import 'package:freezed_annotation/freezed_annotation.dart';

part 'transit_path.freezed.dart';

/// 경로의 한 구간.
@freezed
sealed class TransitLeg with _$TransitLeg {
  const factory TransitLeg.walk({
    required int minutes,
    required int distanceM,
  }) = TransitWalkLeg;

  const factory TransitLeg.subway({
    required int minutes,
    required String lineName,
    int? subwayCode,
    required String start,
    required String end,
    required int stationCount,
    required String way,
  }) = TransitSubwayLeg;

  const factory TransitLeg.bus({
    required int minutes,
    required List<String> busNumbers,
    required String start,
    required String end,
    required int stationCount,
  }) = TransitBusLeg;
}

/// 출발지에서 도착지까지 대중교통 경로 하나.
@freezed
class TransitPath with _$TransitPath {
  @override
  final int totalMinutes;

  @override
  final int transferCount;

  @override
  final int? fare;

  @override
  final List<TransitLeg> legs;

  const TransitPath({
    required this.totalMinutes,
    required this.transferCount,
    this.fare,
    required this.legs,
  });

  /// 도보 구간 시간의 합.
  int get walkMinutes =>
      legs.whereType<TransitWalkLeg>().fold(0, (a, l) => a + l.minutes);
}
