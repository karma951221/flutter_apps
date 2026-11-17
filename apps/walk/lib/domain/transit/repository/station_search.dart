import '../entity/station_hit.dart';

abstract interface class StationSearch {
  Future<List<StationHit>> search(String query, {required String apiKey});
}
