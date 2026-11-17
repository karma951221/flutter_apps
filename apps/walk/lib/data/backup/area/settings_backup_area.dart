import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../../domain/transit/usecase/transit_api_key.dart';
import '../../commute/prefs_place_repository.dart';
import '../../location/prefs_location_preferences.dart';
import '../../location/prefs_map_style_preferences.dart';
import '../../settings/prefs_settings_repository.dart';
import '../../transit/secure_transit_key_store.dart';
import 'area_io.dart';
import 'prefs_snapshot.dart';

const _prefsFile = 'prefs.json';

/// 앱 설정 중 백업에 담는 키. 허용 목록만 담는다 — API 키 · 키 상태(길찾기 `transit.keyStatus` 만 예외) · 동의 · 잠금 · 캐시 ·
/// 일시 상태(`walk.goalCelebratedOn`)는 빼고, 알람 · 일기 · 대화 설정은 각 영역이 담는다.
/// 물어보기 벤더 · 모델 · 빠른 모드(`chat.vendor` · `chat.model` · `chat.fastMode*`)도 뺀다 —
/// API 키를 따라가는 값인데 키는 담지 않으므로, 벤더만 바뀌면 지금 기기의 키를 다른 벤더로 보낸다.
const _prefKeys = {
  PrefsSettingsRepository.themeModeKey,
  PrefsSettingsRepository.stepGoalKey,
  PrefsMapStylePreferences.styleKey,
  PrefsLocationPreferences.retentionKey,
  PrefsPlaceRepository.homeKey,
  PrefsPlaceRepository.workKey,
  // 길찾기를 쓴 적 있는지만 따라간다(비밀 아님). 키 자체는 담지 않는다.
  SecureTransitKeyStore.statusKey,
};

/// 앱 설정 영역. `settings/prefs.json` 하나를 쓴다.
class SettingsBackupArea implements BackupAreaSource {
  SettingsBackupArea(this._prefs, this._transitKey);

  final SharedPreferences _prefs;

  /// 길찾기 키는 백업에 담지 않으므로 복원 뒤 쓸 수 있는 키가 있는지만 본다.
  final TransitApiKey _transitKey;

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.settings;

  @override
  Map<String, int> get schema => const {'prefs': 1};

  /// 백업 시트에 개수를 보여 주지 않는다.
  @override
  Future<Map<String, int>> counts() async => const {};

  @override
  Future<int> estimatedBytes() async =>
      utf8.encode(jsonEncode(await dumpPrefs(_prefs, _prefKeys))).length;

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    await out.create(recursive: true);
    await writeAreaJson(out, _prefsFile, await dumpPrefs(_prefs, _prefKeys));
    return const {};
  }

  @override
  Future<void> validate(Directory root) =>
      readPrefsSnapshot(_areaDir(root), _prefsFile, _prefKeys);

  @override
  Future<void> replace(Directory root) async {
    final prefs = await readPrefsSnapshot(
      _areaDir(root),
      _prefsFile,
      _prefKeys,
    );
    await restorePrefs(_prefs, _prefKeys, prefs);
  }

  @override
  Future<Set<RestoreNotice>> afterRestore() async => {
    if (_prefs.containsKey(SecureTransitKeyStore.statusKey) &&
        await _transitKey.current() == null)
      RestoreNotice.transitKeyNeeded,
  };
}
