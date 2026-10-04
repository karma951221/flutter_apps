import 'package:core/core.dart';

import '../entity/dog.dart';

abstract interface class DogRepository {
  Stream<Result<List<Dog>>> watchAll();

  Future<Result<List<Dog>>> getAll();

  Future<Result<Dog?>> findById(String id);

  Future<Result<void>> upsert(Dog dog);

  Future<Result<void>> delete(String id);
}
