import 'dart:typed_data';

import 'package:core/core.dart';

import '../../repository/photo_storage.dart';

class StorePhotoScenario {
  const StorePhotoScenario(this._storage);

  final PhotoStorage _storage;

  Future<Result<String>> call({
    required Uint8List bytes,
    required String extension,
  }) => _storage.store(bytes: bytes, extension: extension);
}
