import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../chat/secure_chat_settings.dart';
import '../../commute/prefs_place_repository.dart';
import '../../location/prefs_location_preferences.dart';
import '../../location/prefs_map_style_preferences.dart';
import '../../settings/prefs_settings_repository.dart';
import 'area_io.dart';
import 'prefs_snapshot.dart';

const _prefsFile = 'prefs.json';

/// 앱 설정 중 백업에 담는 키. 허용 목록만 담는다 — API 키 · 키 상태 · 동의 · 잠금 · 캐시 ·
/// 일시 상태(`walk.goalCelebratedOn`)는 빼고, 알람 · 일기 · 대화 설정은 각 영역이 담는다.
const _prefKeys = {
  PrefsSettingsRepository.themeModeKey,
  PrefsSettingsRepository.stepGoalKey,
  PrefsMapStylePreferences.styleKey,
  PrefsLocationPreferences.retentionKey,
  SecureChatSettings.vendorKey,
  SecureChatSettings.modelKey,
  SecureChatSettings.fastModeKey,
  SecureChatSettings.fastModeAckKey,
  PrefsPlaceRepository.homeKey,
  PrefsPlaceRepository.workKey,
};

/// 앱 설정 영역. `settings/prefs.json` 하나를 쓴다.
class SettingsBackupArea implements BackupAreaSource {
  SettingsBackupArea(this._prefs);

  final SharedPreferences _prefs;

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
  Future<void> afterRestore() async {}
}
