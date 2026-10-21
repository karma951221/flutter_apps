import 'package:walk/domain/commute/entity/train_arrival.dart';

/// 한 역의 실시간 지하철 도착 정보를 준다.
abstract interface class SubwayArrivalSource {
  /// [station] 역에서 [odsayLaneCode] 노선의 [wayCode](1 상행·내선, 2 하행·외선)
  /// 방향으로 오는 열차를 가까운 순 최대 2대 돌려준다.
  ///
  /// 노선 매핑이 없으면 `[]`. 네트워크 · 시간 초과는 `CommuteFailure.network()`,
  /// 서비스 오류는 `CommuteFailure.server(message)` 를 던진다.
  Future<List<TrainArrival>> arrivals({
    required String station,
    required int odsayLaneCode,
    required int wayCode,
  });
}
