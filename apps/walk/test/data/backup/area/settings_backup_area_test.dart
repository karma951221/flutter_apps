import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/area/settings_backup_area.dart';
import 'package:walk/data/profile/prefs_profile_repository.dart';
import 'package:walk/domain/profile/profile.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';

/// 앱 설정 영역의 허용 목록 전부(저장소가 쓰는 타입 그대로).
const _settings = <String, Object>{
  'walk.themeMode': 'dark',
  'walk.stepGoal': 8000,
  'walk.map.style': 'satellite',
  'walk.location.retention': 'days90',
  'commute.place.home': '{"kind":"home","lat":37.5,"lng":127.0}',
  'commute.place.work': '{"kind":"work","lat":37.4,"lng":127.1}',
};

/// API 키를 따라가는 물어보기 설정. 키는 담지 않으므로 이것도 담지 않는다 —
/// 벤더만 바뀌면 지금 기기의 키를 다른 벤더로 보낸다.
const _keyBound = <String, Object>{
  'chat.vendor': 'openai',
  'chat.model': 'gpt-5',
  'chat.fastMode': true,
  'chat.fastMode.ack': true,
};

/// 담으면 안 되는 키 — 비밀 · 동의 · 잠금 · 캐시 · 다른 영역 몫.
const _excluded = <String, Object>{
  ..._keyBound,
  'chat.apiKey': 'sk-secret',
  'anthropic_api_key': 'sk-old',
  'chat.keyStatus': 'valid',
  'chat.consentedVendor': 'anthropic',
  'chat.consented': true,
  'chat.consentScope': 2,
  'walk.lock.enabled': true,
  'walk.lock.hash': 'h',
  'walk.lock.salt': 's',
  'walk.holidays.cache': '{}',
  'weather.cache.v1': '{}',
  'chat.models': '[]',
  'chat.models.vendor': 'openai',
  'walk.goalCelebratedOn': '2026-11-16',
  'walk.alarms': '[]',
  'walk.diary.trashRetention': 'day30',
  'walk.chat.retention': 'days30',
};

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

void main() {
  late Directory tmp;
  late Directory staging;
  late Directory docsA;
  late Directory docsB;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('settings_backup_area_test');
    staging = Directory('${tmp.path}/staging')..createSync();
    docsA = Directory('${tmp.path}/docsA')..createSync();
    docsB = Directory('${tmp.path}/docsB')..createSync();
  });

  var clock = 0;
  PrefsProfileRepository profileOf(SharedPreferences prefs, Directory docs) =>
      PrefsProfileRepository.withEncoder(
        prefs,
        docs,
        encode: (src, dst) async => File(src).copy(dst),
        now: () => ++clock,
      );

  /// 프로필 저장소를 [docs] 에 둔 영역. 기본은 [docsA].
  SettingsBackupArea areaOf(SharedPreferences prefs, [Directory? docs]) =>
      SettingsBackupArea(prefs, profileOf(prefs, docs ?? docsA));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('settings export contains exactly the allowlist', () async {
    SharedPreferences.setMockInitialValues({..._settings, ..._excluded});
    final area = areaOf(await SharedPreferences.getInstance());

    expect(await area.export(staging), isEmpty);

    final written =
        jsonDecode(
              File('${staging.path}/settings/prefs.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(written.keys.toSet(), _settings.keys.toSet());
    for (final key in _keyBound.keys) {
      expect(written.containsKey(key), isFalse, reason: key);
    }
  });

  test('settings round trip keeps types and leaves other keys alone', () async {
    SharedPreferences.setMockInitialValues(_settings);
    await areaOf(await SharedPreferences.getInstance()).export(staging);

    SharedPreferences.setMockInitialValues({
      ..._excluded,
      'walk.themeMode': 'light',
    });
    final prefsB = await SharedPreferences.getInstance();
    final areaB = areaOf(prefsB, docsB);
    await areaB.validate(staging);
    await areaB.replace(staging);
    await areaB.afterRestore();

    for (final e in _settings.entries) {
      expect(prefsB.get(e.key), e.value, reason: e.key);
    }
    for (final e in _excluded.entries) {
      expect(prefsB.get(e.key), e.value, reason: e.key);
    }
  });

  test('replace removes allowlisted keys absent from backup', () async {
    SharedPreferences.setMockInitialValues({});
    await areaOf(await SharedPreferences.getInstance()).export(staging);

    SharedPreferences.setMockInitialValues(_settings);
    final prefsB = await SharedPreferences.getInstance();
    await areaOf(prefsB, docsB).replace(staging);

    for (final key in _settings.keys) {
      expect(prefsB.containsKey(key), isFalse, reason: key);
    }
  });

  test('validate rejects malformed prefs.json', () async {
    SharedPreferences.setMockInitialValues({});
    final area = areaOf(await SharedPreferences.getInstance());
    await area.export(staging);
    File(
      '${staging.path}/settings/prefs.json',
    ).writeAsStringSync('{"walk.stepGoal":{"type":"int","value":"many"}}');

    expect(
      await _failureOf(() => area.validate(staging)),
      BackupFailure.integrity,
    );
  });

  test('id, schema and counts', () async {
    SharedPreferences.setMockInitialValues(_settings);
    final area = areaOf(await SharedPreferences.getInstance());

    expect(area.id, BackupAreaId.settings);
    expect(area.schema, {'prefs': 1, 'profile': 1});
    expect(await area.counts(), isEmpty);
    expect(await area.estimatedBytes(), greaterThan(0));
  });

  group('profile', () {
    Future<String> photo(Directory dir, String body) async {
      final f = File('${dir.path}/src-$body.jpg');
      await f.writeAsString(body);
      return f.path;
    }

    test('이름 · 소개 · 사진을 담고, 토글은 담지 않는다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsA = await SharedPreferences.getInstance();
      final repoA = profileOf(prefsA, docsA);
      await repoA.save(
        const Profile(name: '하늘', bio: '걷는 사람', shareNameWithAi: true),
      );
      await repoA.setPhoto(await photo(tmp, 'face'));
      await SettingsBackupArea(prefsA, repoA).export(staging);

      final prefsJson = File(
        '${staging.path}/settings/prefs.json',
      ).readAsStringSync();
      expect(prefsJson, isNot(contains('profile.')));

      SharedPreferences.setMockInitialValues({});
      final prefsB = await SharedPreferences.getInstance();
      final repoB = profileOf(prefsB, docsB);
      await repoB.save(const Profile(shareNameWithAi: true));
      final areaB = SettingsBackupArea(prefsB, repoB);
      await areaB.validate(staging);
      await areaB.replace(staging);

      final restored = repoB.load();
      expect(restored.name, '하늘');
      expect(restored.bio, '걷는 사람');
      expect(restored.shareNameWithAi, isFalse);
      expect(File(repoB.photoPath(restored)!).readAsStringSync(), 'face');
    });

    test('사진 없는 백업은 지금 사진을 지운다', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsA = await SharedPreferences.getInstance();
      await areaOf(prefsA).export(staging);

      SharedPreferences.setMockInitialValues({});
      final prefsB = await SharedPreferences.getInstance();
      final repoB = profileOf(prefsB, docsB);
      final before = await repoB.setPhoto(await photo(tmp, 'old'));
      await SettingsBackupArea(prefsB, repoB).replace(staging);

      expect(repoB.load().photo, isNull);
      expect(File(repoB.photoPath(before)!).existsSync(), isFalse);
    });

    test('프로필이 없는 옛 백업은 지금 프로필을 둔다', () async {
      SharedPreferences.setMockInitialValues({});
      await areaOf(await SharedPreferences.getInstance()).export(staging);
      File('${staging.path}/settings/profile.json').deleteSync();

      SharedPreferences.setMockInitialValues({});
      final prefsB = await SharedPreferences.getInstance();
      final repoB = profileOf(prefsB, docsB);
      await repoB.save(const Profile(name: '지금', shareNameWithAi: true));
      final kept = await repoB.setPhoto(await photo(tmp, 'now'));
      final areaB = SettingsBackupArea(prefsB, repoB);
      await areaB.validate(staging);
      await areaB.replace(staging);

      expect(repoB.load(), kept);
      expect(File(repoB.photoPath(kept)!).existsSync(), isTrue);
    });

    test('사진 경로가 영역 밖이거나 파일이 없으면 integrity', () async {
      SharedPreferences.setMockInitialValues({});
      final area = areaOf(await SharedPreferences.getInstance());
      await area.export(staging);
      final json = File('${staging.path}/settings/profile.json');

      json.writeAsStringSync('{"name":"a","bio":"","photo":"../../x.jpg"}');
      expect(
        await _failureOf(() => area.validate(staging)),
        BackupFailure.integrity,
      );

      json.writeAsStringSync('{"name":"a","bio":"","photo":"missing.jpg"}');
      expect(
        await _failureOf(() => area.validate(staging)),
        BackupFailure.integrity,
      );

      json.writeAsStringSync('{"name":3,"bio":""}');
      expect(
        await _failureOf(() => area.validate(staging)),
        BackupFailure.integrity,
      );
    });
  });
}
