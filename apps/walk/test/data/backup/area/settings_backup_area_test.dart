import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/area/settings_backup_area.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/restore_notice.dart';
import 'package:walk/domain/transit/repository/transit_key_store.dart';
import 'package:walk/domain/transit/usecase/transit_api_key.dart';

/// 앱 설정 영역의 허용 목록 전부(저장소가 쓰는 타입 그대로).
const _settings = <String, Object>{
  'walk.themeMode': 'dark',
  'walk.stepGoal': 8000,
  'walk.map.style': 'satellite',
  'walk.location.retention': 'days90',
  'commute.place.home': '{"kind":"home","lat":37.5,"lng":127.0}',
  'commute.place.work': '{"kind":"work","lat":37.4,"lng":127.1}',
  'transit.keyStatus': 'connected',
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

class _FakeKeyStore implements TransitKeyStore {
  _FakeKeyStore(this.key);
  final String? key;
  @override
  Future<String?> read() async => key;
  @override
  Future<void> save(String key, TransitKeyStatus status) async {}
  @override
  Future<void> delete() async {}
  @override
  Future<TransitKeyStatus?> status() async => null;
  @override
  Future<void> setStatus(TransitKeyStatus s) async {}
}

SettingsBackupArea _area(SharedPreferences prefs, {String? savedKey}) =>
    SettingsBackupArea(
      prefs,
      TransitApiKey(_FakeKeyStore(savedKey), fallback: ''),
    );

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

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('settings_backup_area_test');
    staging = Directory('${tmp.path}/staging')..createSync();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('settings export contains exactly the allowlist', () async {
    SharedPreferences.setMockInitialValues({..._settings, ..._excluded});
    final area = _area(await SharedPreferences.getInstance());

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
    await _area(await SharedPreferences.getInstance()).export(staging);

    SharedPreferences.setMockInitialValues({
      ..._excluded,
      'walk.themeMode': 'light',
    });
    final prefsB = await SharedPreferences.getInstance();
    final areaB = _area(prefsB);
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
    await _area(await SharedPreferences.getInstance()).export(staging);

    SharedPreferences.setMockInitialValues(_settings);
    final prefsB = await SharedPreferences.getInstance();
    await _area(prefsB).replace(staging);

    for (final key in _settings.keys) {
      expect(prefsB.containsKey(key), isFalse, reason: key);
    }
  });

  test('validate rejects malformed prefs.json', () async {
    SharedPreferences.setMockInitialValues({});
    final area = _area(await SharedPreferences.getInstance());
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
    final area = _area(await SharedPreferences.getInstance());

    expect(area.id, BackupAreaId.settings);
    expect(area.schema, {'prefs': 1});
    expect(await area.counts(), isEmpty);
    expect(await area.estimatedBytes(), greaterThan(0));
  });

  test('transit keys are not in backup allow-list', () async {
    SharedPreferences.setMockInitialValues({
      ..._settings,
      'transit.odsayKey': 'secret',
      'transit.recent': '[]',
      'transit.stationCache': '{}',
    });
    final area = _area(await SharedPreferences.getInstance());
    await area.export(staging);

    final written =
        jsonDecode(
              File('${staging.path}/settings/prefs.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(written.keys.where((k) => k.startsWith('transit.')), [
      'transit.keyStatus',
    ]);
  });

  test(
    'afterRestore asks for a transit key only if transit was used',
    () async {
      SharedPreferences.setMockInitialValues({});
      final never = await SharedPreferences.getInstance();
      expect(await _area(never).afterRestore(), isEmpty);

      SharedPreferences.setMockInitialValues({
        'transit.keyStatus': 'connected',
      });
      final used = await SharedPreferences.getInstance();
      expect(await _area(used).afterRestore(), {
        RestoreNotice.transitKeyNeeded,
      });
      expect(await _area(used, savedKey: 'k').afterRestore(), isEmpty);
    },
  );
}
