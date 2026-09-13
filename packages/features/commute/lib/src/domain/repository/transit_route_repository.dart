import 'package:core/core.dart';

import '../entity/geo_point.dart';
import '../entity/transit_route.dart';

abstract interface class TransitRouteRepository {
  Future<Result<List<TransitRoute>>> search({
    required GeoPoint origin,
    required GeoPoint destination,
  });
}
