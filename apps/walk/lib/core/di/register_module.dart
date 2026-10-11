import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/diary/database/diary_database.dart';
import '../../data/diary/location/current_place_source.dart';
import '../../data/diary/location/geocoding_place_namer.dart';
import '../../domain/diary/location/place_source.dart';

/// getIt.reset · 테스트 해제 때 DB 를 닫는다.
FutureOr<void> disposeDiaryDatabase(DiaryDatabase db) => db.close();

/// 직접 소유하지 않는 인스턴스 등록.
@module
abstract class RegisterModule {
  /// DI 준비 중에 미리 받아 둔다(`@preResolve`). 값 읽기가 동기가 되어
  /// 첫 프레임부터 저장된 테마로 뜬다.
  @preResolve
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();

  /// `core` 의 시계. 이 앱은 Supabase 를 등록하는 `CorePackageModule` 을 쓰지 않아
  /// 여기서 직접 등록한다.
  @lazySingleton
  Clock get clock => const Clock();

  @LazySingleton(dispose: disposeDiaryDatabase)
  DiaryDatabase diaryDatabase(Clock clock) =>
      DiaryDatabase(driftDatabase(name: 'diary'), now: clock.now);

  /// 일기 미디어가 사는 폴더. DI 준비 중에 경로를 받아 둔다.
  @preResolve
  @Named('diaryRoot')
  Future<Directory> get diaryRoot async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/diary');
  }

  /// 이 앱은 `CorePackageModule` 을 쓰지 않아 `IdGenerator` 와 그 재료도 직접
  /// 등록한다.
  @lazySingleton
  Uuid get uuid => const Uuid();

  @lazySingleton
  IdGenerator idGenerator(Uuid uuid) => IdGenerator(uuid);

  @lazySingleton
  LocationGateway get locationGateway => const GeolocatorGateway();

  /// 위치 권한을 세션당 한 번만 묻는 기억을 가지므로 하나만 둔다.
  @lazySingleton
  LocationAccess locationAccess(LocationGateway gateway) =>
      LocationAccess(gateway);

  @lazySingleton
  PlaceNamer get placeNamer => GeocodingPlaceNamer();

  @lazySingleton
  PlaceSource placeSource(
    LocationAccess access,
    LocationGateway gateway,
    PlaceNamer namer,
  ) => CurrentPlaceSource(access, gateway, namer);
}
