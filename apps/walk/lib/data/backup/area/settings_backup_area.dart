import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/backup_failure.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../../domain/profile/profile.dart';
import '../../../domain/profile/profile_repository.dart';
import '../../../domain/transit/usecase/transit_api_key.dart';
import '../../commute/prefs_place_repository.dart';
import '../../location/prefs_location_preferences.dart';
import '../../location/prefs_map_style_preferences.dart';
import '../../profile/prefs_profile_repository.dart';
import '../../settings/prefs_settings_repository.dart';
import '../../transit/secure_transit_key_store.dart';
import 'area_io.dart';
import 'prefs_snapshot.dart';

const _prefsFile = 'prefs.json';
const _profileFile = 'profile.json';
const _profileDir = 'profile';

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

/// 앱 설정 영역. `settings/prefs.json` 과 프로필(`settings/profile.json` · `settings/profile/<사진>`)을 쓴다.
///
/// 프로필은 이름 · 소개 · 사진만 담는다. "물어보기에 이름 알려주기"는 외부 전송 동의 성격이라 담지 않고,
/// 복원하면 꺼진다. `profile.json` 이 없는 옛 백업은 지금 프로필을 그대로 둔다.
class SettingsBackupArea implements BackupAreaSource {
  SettingsBackupArea(this._prefs, this._profile, this._transitKey);

  final SharedPreferences _prefs;
  final ProfileRepository _profile;

  /// 길찾기 키는 백업에 담지 않으므로 복원 뒤 쓸 수 있는 키가 있는지만 본다.
  final TransitApiKey _transitKey;

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.settings;

  @override
  Map<String, int> get schema => const {'prefs': 1, 'profile': 1};

  /// 백업 시트에 개수를 보여 주지 않는다.
  @override
  Future<Map<String, int>> counts() async => const {};

  @override
  Future<int> estimatedBytes() async {
    final prefs = utf8.encode(jsonEncode(await dumpPrefs(_prefs, _prefKeys)));
    final path = _profile.photoPath(_profile.load());
    final photo = path == null ? null : File(path);
    final photoBytes = photo != null && photo.existsSync()
        ? await photo.length()
        : 0;
    return prefs.length + photoBytes;
  }

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    await out.create(recursive: true);
    await writeAreaJson(out, _prefsFile, await dumpPrefs(_prefs, _prefKeys));
    await _exportProfile(out);
    return const {};
  }

  Future<void> _exportProfile(Directory out) async {
    final profile = _profile.load();
    final path = _profile.photoPath(profile);
    String? photo;
    if (path != null && File(path).existsSync()) {
      final dir = Directory('${out.path}/$_profileDir');
      await dir.create();
      await File(path).copy('${dir.path}/${profile.photo}');
      photo = profile.photo;
    }
    await writeAreaJson(out, _profileFile, {
      'name': profile.name,
      'bio': profile.bio,
      'photo': photo,
    });
  }

  @override
  Future<void> validate(Directory root) async {
    await readPrefsSnapshot(_areaDir(root), _prefsFile, _prefKeys);
    await _readProfile(_areaDir(root));
  }

  /// 백업의 프로필. 옛 백업(파일 없음)이면 null. 모양이 다르거나 사진이 없으면 integrity.
  Future<({String name, String bio, String? photo})?> _readProfile(
    Directory dir,
  ) async {
    if (!File('${dir.path}/$_profileFile').existsSync()) return null;
    final json = await readAreaJson(dir, _profileFile);
    final profile = switch (json) {
      {'name': final String name, 'bio': final String bio} => (
        name: name,
        bio: bio,
        photo: json['photo'],
      ),
      _ => throw const BackupException(BackupFailure.integrity),
    };
    final photo = profile.photo;
    if (photo == null) {
      return (name: profile.name, bio: profile.bio, photo: null);
    }
    if (photo is! String ||
        !PrefsProfileRepository.isSafeFileName(photo) ||
        !File('${dir.path}/$_profileDir/$photo').existsSync()) {
      throw const BackupException(BackupFailure.integrity);
    }
    return (
      name: profile.name,
      bio: profile.bio,
      photo: '${dir.path}/$_profileDir/$photo',
    );
  }

  @override
  Future<void> replace(Directory root) async {
    final prefs = await readPrefsSnapshot(
      _areaDir(root),
      _prefsFile,
      _prefKeys,
    );
    final profile = await _readProfile(_areaDir(root));
    await restorePrefs(_prefs, _prefKeys, prefs);
    if (profile == null) return;
    final photo = profile.photo;
    if (photo == null) {
      await _profile.clearPhoto();
    } else {
      await _profile.setPhoto(photo);
    }
    await _profile.save(
      Profile(
        name: profile.name.characters.take(Profile.maxName).toString(),
        bio: profile.bio.characters.take(Profile.maxBio).toString(),
      ),
    );
  }

  @override
  Future<Set<RestoreNotice>> afterRestore() async => {
    if (_prefs.containsKey(SecureTransitKeyStore.statusKey) &&
        await _transitKey.current() == null)
      RestoreNotice.transitKeyNeeded,
  };
}
