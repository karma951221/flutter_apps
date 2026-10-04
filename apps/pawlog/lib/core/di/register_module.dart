import 'dart:async';
import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database/walk_database.dart';

/// getIt.reset · 테스트 해제 때 DB 를 닫는다.
FutureOr<void> disposeWalkDatabase(WalkDatabase db) => db.close();

/// 직접 소유하지 않는 인스턴스 등록.
@module
abstract class RegisterModule {
  @LazySingleton(dispose: disposeWalkDatabase)
  WalkDatabase get database => WalkDatabase(driftDatabase(name: 'pawlog'));

  @preResolve
  @Named('walkPhotosRoot')
  Future<Directory> get photosRoot async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/pawlog_photos');
  }

  /// 지도 위젯이 getIt 에서 받아 가므로 테스트가 대체할 수 있다.
  @lazySingleton
  TileProvider get tileProvider => NetworkTileProvider();
}
