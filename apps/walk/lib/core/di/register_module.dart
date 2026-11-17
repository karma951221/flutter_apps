import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/app_version.dart';
import '../config/commute_api_keys.dart';
import '../../data/alarm/archive/ring_archive_database.dart';
import '../../data/backup/area/alarm_backup_area.dart';
import '../../data/backup/area/chat_backup_area.dart';
import '../../data/backup/area/diary_backup_area.dart';
import '../../data/backup/area/location_backup_area.dart';
import '../../data/backup/area/settings_backup_area.dart';
import '../../data/backup/area/wiki_backup_area.dart';
import '../../data/backup/default_backup_service.dart';
import '../../data/chat/database/chat_database.dart';
import '../../data/chat/dev_chat_trace.dart';
import '../../data/diary/database/diary_database.dart';
import '../../data/diary/location/current_place_source.dart';
import '../../data/diary/location/geocoding_place_namer.dart';
import '../../data/location/database/location_database.dart';
import '../../domain/alarm/permission/alarm_permissions.dart';
import '../../domain/alarm/usecase/alarm_use_case.dart';
import '../../domain/backup/backup_area_source.dart';
import '../../domain/backup/backup_files.dart';
import '../../domain/location/recorder/location_recorder.dart';
import '../../domain/backup/backup_service.dart';
import '../../domain/chat/chat_settings.dart';
import '../../domain/chat/chat_trace.dart';
import '../../domain/diary/location/place_source.dart';
import '../../domain/profile/profile_repository.dart';
import '../../domain/transit/repository/transit_key_store.dart';
import '../../domain/transit/usecase/transit_api_key.dart';

/// getIt.reset · 테스트 해제 때 DB 를 닫는다.
FutureOr<void> disposeDiaryDatabase(DiaryDatabase db) => db.close();

FutureOr<void> disposeRingArchiveDatabase(RingArchiveDatabase db) => db.close();

FutureOr<void> disposeChatDatabase(ChatDatabase db) => db.close();

FutureOr<void> disposeLocationDatabase(LocationDatabase db) => db.close();

/// 직접 소유하지 않는 인스턴스 등록.
@module
abstract class RegisterModule {
  /// DI 준비 중에 미리 받아 둔다(`@preResolve`). 값 읽기가 동기가 되어
  /// 첫 프레임부터 저장된 테마로 뜬다.
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  /// `core` 의 시계. 이 앱은 Supabase 를 등록하는 `CorePackageModule` 을 쓰지 않아
  /// 여기서 직접 등록한다.
  @lazySingleton
  Clock get clock => const Clock();

  @LazySingleton(dispose: disposeDiaryDatabase)
  DiaryDatabase diaryDatabase(Clock clock) =>
      DiaryDatabase(driftDatabase(name: 'diary'), now: clock.now);

  /// 네이티브 200줄 울림 기록을 오래 남기는 보관소(채팅이 읽는다).
  @LazySingleton(dispose: disposeRingArchiveDatabase)
  RingArchiveDatabase ringArchiveDatabase() =>
      RingArchiveDatabase(driftDatabase(name: 'ring_archive'));

  /// 물어보기 대화 · 사용량(2단계에 위키). 일기 DB 와 따로 — 백업 · 휴지통 · 스키마 버전과 엮이지 않게.
  @LazySingleton(dispose: disposeChatDatabase)
  ChatDatabase chatDatabase() => ChatDatabase(driftDatabase(name: 'chat'));

  /// 위치 기록 점. 일기 DB 와 따로 — 이 폰에만 쌓이고 보관 기간으로 따로 지운다.
  @LazySingleton(dispose: disposeLocationDatabase)
  LocationDatabase locationDatabase() =>
      LocationDatabase(driftDatabase(name: 'location'));

  /// 일기 미디어가 사는 폴더. DI 준비 중에 경로를 받아 둔다.
  @preResolve
  @Named('diaryRoot')
  Future<Directory> get diaryRoot async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/diary');
  }

  /// 문서 폴더(`app_flutter`). 백업의 작업 · 되돌리기 폴더가 여기 산다.
  @preResolve
  @Named('appDocs')
  Future<Directory> get appDocs => getApplicationDocumentsDirectory();

  /// 앱 캐시 폴더. 만든 백업 파일을 사용자 위치로 저장하기 전에 둔다.
  @preResolve
  @Named('appCache')
  Future<Directory> get appCache => getTemporaryDirectory();

  /// 물어보기 작업 폴더(`FileWorkspace.standard` 와 같은 경로).
  @lazySingleton
  @Named('workspaceRoot')
  Directory workspaceRoot(@Named('appDocs') Directory docs) =>
      Directory('${docs.path}/workspace');

  /// 알람음 사본 폴더. 네이티브 `getDir("flutter")/alarm_sounds` 와 같은 곳이다.
  @lazySingleton
  @Named('alarmSoundsRoot')
  Directory alarmSoundsRoot(@Named('appDocs') Directory docs) =>
      Directory('${docs.path}/alarm_sounds');

  @lazySingleton
  DiaryBackupArea diaryBackupArea(
    DiaryDatabase db,
    @Named('diaryRoot') Directory root,
    SharedPreferences prefs,
  ) => DiaryBackupArea(db, root, prefs);

  @lazySingleton
  ChatBackupArea chatBackupArea(
    ChatDatabase db,
    @Named('workspaceRoot') Directory root,
    SharedPreferences prefs,
    ChatSettings settings,
  ) => ChatBackupArea(db, root, prefs, settings);

  @lazySingleton
  WikiBackupArea wikiBackupArea(ChatDatabase db, SharedPreferences prefs) =>
      WikiBackupArea(db, prefs);

  @lazySingleton
  AlarmBackupArea alarmBackupArea(
    SharedPreferences prefs,
    RingArchiveDatabase archive,
    @Named('alarmSoundsRoot') Directory sounds,
    AlarmUseCase alarms,
    AlarmPermissions permissions,
  ) => AlarmBackupArea(prefs, archive, sounds, alarms, permissions);

  @lazySingleton
  SettingsBackupArea settingsBackupArea(
    SharedPreferences prefs,
    ProfileRepository profile,
    TransitApiKey transitKey,
  ) => SettingsBackupArea(prefs, profile, transitKey);

  /// 길찾기 키 — 보안 저장소 다음에 빌드 주입(`CommuteApiKeys.odsay`)을 쓴다.
  @lazySingleton
  TransitApiKey transitApiKey(TransitKeyStore store, CommuteApiKeys keys) =>
      TransitApiKey(store, fallback: keys.odsay);

  @lazySingleton
  LocationBackupArea locationBackupArea(
    LocationDatabase db,
    LocationRecorder recorder,
  ) => LocationBackupArea(db, recorder);

  /// 백업 영역 전부, `BackupAreaId` 순서(대화가 위키보다 먼저).
  @lazySingleton
  List<BackupAreaSource> backupAreas(
    DiaryBackupArea diary,
    ChatBackupArea chat,
    WikiBackupArea wiki,
    AlarmBackupArea alarm,
    SettingsBackupArea settings,
    LocationBackupArea location,
  ) => [diary, chat, wiki, alarm, settings, location];

  /// 여유 공간은 백업 채널이 앱 캐시 저장소(문서 폴더와 같은 데이터 파티션)에서 읽는다.
  @lazySingleton
  BackupService backupService(
    List<BackupAreaSource> areas,
    @Named('appDocs') Directory docs,
    @Named('appCache') Directory cache,
    Clock clock,
    BackupFiles files,
  ) => DefaultBackupService(
    areas: areas,
    appDocs: docs,
    cache: cache,
    appVersion: appVersion,
    clock: clock,
    freeBytes: files.freeBytes,
  );

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

  /// 일기 잠금의 폰 인증(`LocalAuthDeviceAuth`)이 쓴다.
  @lazySingleton
  LocalAuthentication get localAuthentication => LocalAuthentication();

  @lazySingleton
  PlaceNamer get placeNamer => GeocodingPlaceNamer();

  /// 지도 타일(OSM). 지도 위젯이 getIt 에서 받아 가므로 테스트가 대체할 수 있다.
  ///
  /// 싱글턴이면 안 된다 — TileLayer 가 사라질 때 provider 를 dispose 하고,
  /// NetworkTileProvider 는 그때 자기 http client 를 닫아 다음 지도가 회색이 된다.
  @injectable
  TileProvider get tileProvider => NetworkTileProvider();

  @lazySingleton
  PlaceSource placeSource(
    LocationAccess access,
    LocationGateway gateway,
    PlaceNamer namer,
  ) => CurrentPlaceSource(access, gateway, namer);

  /// 통근 탭의 ODsay · 서울 실시간 도착 호출이 함께 쓴다.
  @lazySingleton
  http.Client get httpClient => http.Client();

  /// `--dart-define-from-file=config/commute_keys.json` 으로 주입한 키. 비면 "키 없음".
  @lazySingleton
  CommuteApiKeys get commuteApiKeys => CommuteApiKeys.fromEnvironment();

  /// 채팅용 Anthropic API 키를 두는 보안 저장소.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// 물어보기 질문 하나의 시간 흐름. 릴리스 빌드에는 아무것도 남지 않는다.
  @lazySingleton
  ChatTrace get chatTrace =>
      kReleaseMode ? const NoopChatTrace() : DevChatTrace();
}
