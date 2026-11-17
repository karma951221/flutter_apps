import '../entity/transit_path.dart';
import '../entity/transit_point.dart';

abstract interface class TransitRouteSource {
  Future<List<TransitPath>> find({
    required TransitPoint from,
    required TransitPoint to,
    required String apiKey,
  });
}
