import '../entity/transit_point.dart';

abstract interface class RecentPoints {
  Future<List<TransitPoint>> load();
  Future<void> add(TransitPoint p);
}
