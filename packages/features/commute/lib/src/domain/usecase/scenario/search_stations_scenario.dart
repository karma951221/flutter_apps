import 'package:core/core.dart';

import '../../entity/station.dart';
import '../../repository/station_repository.dart';

class SearchStationsScenario {
  const SearchStationsScenario(this._repository);

  final StationRepository _repository;

  Future<Result<List<Station>>> call(String query) => _repository.search(query);
}
