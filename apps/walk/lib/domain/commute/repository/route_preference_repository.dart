import 'package:walk/domain/commute/entity/commute_direction.dart';

/// 방향별로 고른 경로의 서명(`TransitRoute.signature`)을 기억한다.
abstract interface class RoutePreferenceRepository {
  String? load(CommuteDirection d);

  Future<void> save(CommuteDirection d, String signature);
}
