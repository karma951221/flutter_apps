import '../entity/station_hit.dart';
import '../entity/transit_path.dart';

abstract interface class TransitCache {
  ({List<TransitPath> paths, DateTime fetchedAt})? routes(String key);
  void putRoutes(String key, List<TransitPath> paths);
  Future<List<StationHit>?> stations(String query);
  Future<void> putStations(String query, List<StationHit> hits);
}
