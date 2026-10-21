import 'entity/catch_verdict.dart';
import 'entity/train_arrival.dart';
import 'entity/transit_route.dart';

/// 승강장에서 열차보다 먼저 도착해 있어야 하는 여유(분).
const kStationBufferMinutes = 1;

/// 조회 후 이 시간이 지나면 오래된 결과로 본다.
const kStaleAfter = Duration(minutes: 2);

/// 걷는 시간만 보고 앞 두 대 중 탈 수 있는 열차를 판단한다.
CatchVerdict judgeCatch(List<TrainArrival> arrivals, int walkMinutes) {
  final valid = _valid(arrivals);
  if (valid.isEmpty) return const CatchVerdict.unknown();
  final need = walkMinutes + kStationBufferMinutes;
  if (valid[0].minutes! >= need) return const CatchVerdict.catchFirst();
  if (valid.length > 1 && valid[1].minutes! >= need) {
    return const CatchVerdict.catchSecond();
  }
  return const CatchVerdict.missBoth();
}

List<TrainArrival> _valid(List<TrainArrival> arrivals) =>
    arrivals.where((a) => a.minutes != null).take(2).toList();

/// 판단에 따라 탈 열차. 알 수 없으면 null.
TrainArrival? boardingTrain(List<TrainArrival> arrivals, CatchVerdict verdict) {
  final valid = _valid(arrivals);
  return switch (verdict) {
    CatchFirst() => valid.isNotEmpty ? valid[0] : null,
    CatchSecond() || MissBoth() => valid.length > 1 ? valid[1] : null,
    CatchUnknown() => null,
  };
}

DateTime estimateEta({
  required DateTime now,
  required TransitRoute route,
  TrainArrival? boarding,
}) {
  final wait = boarding?.minutes;
  if (wait == null) return now.add(Duration(minutes: route.totalMinutes));
  return now.add(Duration(minutes: wait + route.minutesFromBoarding));
}

/// 분이 없고 정거장 수만 있으면 구간 시간 비율로 추정한다.
TrainArrival withEstimatedMinutes(TrainArrival a, SubwayLeg leg) {
  final away = a.stationsAway;
  if (a.minutes != null || away == null || leg.stationCount == 0) return a;
  return a.copyWith(
    minutes: (away * leg.minutes / leg.stationCount).ceil(),
    estimated: true,
  );
}

bool isStale(DateTime queriedAt, DateTime now) =>
    now.difference(queriedAt) >= kStaleAfter;
