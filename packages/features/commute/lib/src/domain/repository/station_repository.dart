import 'package:core/core.dart';

import '../entity/station.dart';

abstract interface class StationRepository {
  Future<Result<List<Station>>> search(String query);

  Future<Result<Station?>> findById(String id);
}
