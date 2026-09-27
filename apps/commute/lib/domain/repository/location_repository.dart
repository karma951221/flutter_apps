import 'package:core/core.dart';

import '../entity/geo_point.dart';

abstract interface class LocationRepository {
  Future<Result<GeoPoint>> currentLocation({
    Duration timeout = const Duration(seconds: 5),
  });
}
