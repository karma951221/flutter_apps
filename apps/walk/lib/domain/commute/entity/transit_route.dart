import 'package:freezed_annotation/freezed_annotation.dart';

part 'transit_route.freezed.dart';

@freezed
sealed class RouteLeg with _$RouteLeg {
  const factory RouteLeg.walk({required int minutes}) = WalkLeg;

  const factory RouteLeg.subway({
    required int minutes,
    required String lineName,
    required int odsayLaneCode,
    required String startStation,
    required String endStation,
    required int wayCode,
    required String wayName,
    required int stationCount,
  }) = SubwayLeg;
}

@freezed
class TransitRoute with _$TransitRoute {
  @override
  final int totalMinutes;

  @override
  final int transferCount;

  @override
  final List<RouteLeg> legs;

  const TransitRoute({
    required this.totalMinutes,
    required this.transferCount,
    required this.legs,
  });

  int get _firstSubwayIndex => legs.indexWhere((l) => l is SubwayLeg);

  SubwayLeg? get firstSubway {
    final i = _firstSubwayIndex;
    return i < 0 ? null : legs[i] as SubwayLeg;
  }

  /// 첫 지하철 앞 도보 구간 합(지하철이 없으면 전체 도보).
  int get walkToStationMinutes {
    final i = _firstSubwayIndex;
    final end = i < 0 ? legs.length : i;
    var sum = 0;
    for (final leg in legs.take(end)) {
      if (leg is WalkLeg) sum += leg.minutes;
    }
    return sum;
  }

  /// 첫 지하철 구간을 포함해 이후 모든 구간의 시간 합.
  int get minutesFromBoarding {
    final i = _firstSubwayIndex;
    if (i < 0) return 0;
    return legs.skip(i).fold(0, (s, l) => s + l.minutes);
  }

  /// 같은 경로인지 비교하는 서명.
  String get signature => legs
      .whereType<SubwayLeg>()
      .map((l) => '${l.odsayLaneCode}:${l.startStation}>${l.endStation}')
      .join('|');
}
