import 'dart:async';
import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission/permission.dart';

import '../../data/database/walk_database.dart';
import '../../data/tracking/notification_permission_source.dart';

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

  @lazySingleton
  LocationGateway get locationGateway => const GeolocatorGateway();

  /// 세션당 한 번 묻는 기억을 가지므로 앱 수명 동안 하나만 둔다.
  @Named('notificationPermission')
  @lazySingleton
  PermissionRequester get notificationPermission =>
      PermissionRequester(const NotificationPermissionSource());

  /// 지도 위젯이 getIt 에서 받아 가므로 테스트가 대체할 수 있다.
  ///
  /// 싱글턴이면 안 된다 — TileLayer 가 사라질 때 provider 를 dispose 하고,
  /// NetworkTileProvider 는 그때 자기 http client 를 닫아 다음 지도가 회색이 된다.
  @injectable
  TileProvider get tileProvider => NetworkTileProvider();
}
