import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/alarm/archive/ring_archive_database.dart';
import 'package:walk/data/alarm/prefs_alarm_repository.dart';
import 'package:walk/data/backup/area/alarm_backup_area.dart';
import 'package:walk/data/backup/area/drift_rows.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/restore_notice.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockAlarmPermissions extends Mock implements AlarmPermissions {}

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

/// 알람 영역이 담는 prefs 중 알람 목록 밖의 것.
const _otherAlarmPrefs = <String, Object>{
  'walk.holidayReminder': false,
  'walk.pauseFrom': '2026-12-24',
  'walk.pauseUntil': '2026-12-26',
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory staging;
  late Directory soundsA; // 기기 A 의 `app_flutter/alarm_sounds`
  late Directory soundsB; // 기기 B 의 같은 폴더(경로가 다르다)
  late RingArchiveDatabase a;
  late RingArchiveDatabase b;
  late _MockAlarmUseCase alarmsA;
  late _MockAlarmUseCase alarmsB;
  late _MockAlarmPermissions perms;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('alarm_backup_area_test');
    staging = Directory('${tmp.path}/staging')..createSync();
    soundsA = Directory('${tmp.path}/a/app_flutter/alarm_sounds')
      ..createSync(recursive: true);
    soundsB = Directory('${tmp.path}/b/app_flutter/alarm_sounds');
    a = RingArchiveDatabase(NativeDatabase.memory());
    b = RingArchiveDatabase(NativeDatabase.memory());
    alarmsA = _MockAlarmUseCase();
    alarmsB = _MockAlarmUseCase();
    when(() => alarmsB.sync()).thenAnswer((_) async {});
    perms = _MockAlarmPermissions();
    when(() => perms.canRing()).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await a.close();
    await b.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> ring(RingArchiveDatabase db, DateTime at, {String? label}) => db
      .into(db.archivedRings)
      .insert(
        ArchivedRingsCompanion.insert(
          at: at,
          packageId: 300,
          kind: RingLogKind.stopped,
          label: Value(label),
        ),
      );

  /// A 에 알람 셋(기기 소리 · 내 파일 · 에셋)과 울림 기록 둘을 만든다.
  Future<List<Alarm>> seedA() async {
    File('${soundsA.path}/abc123.ogg').writeAsBytesSync([1, 2, 3]);
    File('${soundsA.path}/def456.mp3').writeAsBytesSync([4, 5]);
    final alarms = [
      Alarm(
        id: 1,
        hour: 7,
        minute: 0,
        label: '출근',
        sound: AlarmSound.device(
          title: '오프닝',
          path: '${soundsA.path}/abc123.ogg',
        ),
      ),
      Alarm(
        id: 2,
        hour: 8,
        minute: 30,
        sound: AlarmSound.file(
          title: '내 노래',
          path: '${soundsA.path}/def456.mp3',
        ),
      ),
      const Alarm(
        id: 3,
        hour: 22,
        minute: 0,
        sound: AlarmSound.bundled(BundledAlarmSounds.birds),
      ),
    ];
    SharedPreferences.setMockInitialValues({
      PrefsAlarmRepository.key: jsonEncode([
        for (final a in alarms) a.toJson(),
      ]),
      ..._otherAlarmPrefs,
      'walk.alarms.corrupt': 'x',
      'walk.themeMode': 'dark',
    });
    await ring(a, DateTime(2026, 11, 1, 7), label: '출근');
    await ring(a, DateTime(2026, 11, 2, 7));
    return alarms;
  }

  Future<List<Alarm>> alarmsOf(SharedPreferences prefs) =>
      PrefsAlarmRepository(prefs).load();

  test('alarm round trip', () async {
    final alarms = await seedA();
    final areaA = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    );

    final counts = await areaA.export(staging);
    expect(counts, {'alarms': 3});
    expect(await areaA.counts(), counts);

    SharedPreferences.setMockInitialValues({
      'walk.holidayReminder': true,
      'walk.themeMode': 'light',
    });
    final prefsB = await SharedPreferences.getInstance();
    await ring(b, DateTime(2026, 11, 16, 7), label: 'B');
    soundsB.createSync(recursive: true);
    File('${soundsB.path}/b-only.ogg').writeAsBytesSync([0]);
    final areaB = AlarmBackupArea(prefsB, b, soundsB, alarmsB, perms);
    await areaB.validate(staging);
    await areaB.replace(staging);

    expect(
      await dumpTable(b, b.archivedRings),
      await dumpTable(a, a.archivedRings),
    );
    expect(File('${soundsB.path}/abc123.ogg').readAsBytesSync(), [1, 2, 3]);
    expect(File('${soundsB.path}/def456.mp3').readAsBytesSync(), [4, 5]);
    expect(File('${soundsB.path}/b-only.ogg').existsSync(), isFalse);
    expect(Directory('${soundsB.path}.old').existsSync(), isFalse);

    final restored = await alarmsOf(prefsB);
    expect(restored.map((a) => a.id), [1, 2, 3]);
    expect(restored[0].label, alarms[0].label);
    expect(restored[2].sound, alarms[2].sound);
    for (final e in _otherAlarmPrefs.entries) {
      expect(prefsB.get(e.key), e.value, reason: e.key);
    }
    // 알람 영역 밖의 키는 B 그대로.
    expect(prefsB.get('walk.themeMode'), 'light');
    expect(prefsB.containsKey('walk.alarms.corrupt'), isFalse);
  });

  test('rewrites device sound path to current alarm_sounds dir', () async {
    await seedA();
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    ).export(staging);

    SharedPreferences.setMockInitialValues({});
    final prefsB = await SharedPreferences.getInstance();
    await AlarmBackupArea(prefsB, b, soundsB, alarmsB, perms).replace(staging);

    final restored = await alarmsOf(prefsB);
    expect(
      restored[0].sound,
      AlarmSound.device(title: '오프닝', path: '${soundsB.path}/abc123.ogg'),
    );
    expect(
      restored[1].sound,
      AlarmSound.file(title: '내 노래', path: '${soundsB.path}/def456.mp3'),
    );
  });

  test('missing sound file falls back to system', () async {
    await seedA();
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    ).export(staging);
    File('${staging.path}/alarm/sounds/def456.mp3').deleteSync();

    SharedPreferences.setMockInitialValues({});
    final prefsB = await SharedPreferences.getInstance();
    await AlarmBackupArea(prefsB, b, soundsB, alarmsB, perms).replace(staging);

    final restored = await alarmsOf(prefsB);
    expect(restored[0].sound, isA<DeviceAlarmSound>());
    expect(restored[1].sound, const AlarmSound.system());
    expect(restored[1].hour, 8);
  });

  test('afterRestore reports sound fallback once', () async {
    await seedA();
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    ).export(staging);
    File('${staging.path}/alarm/sounds/def456.mp3').deleteSync();

    SharedPreferences.setMockInitialValues({});
    final areaB = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      b,
      soundsB,
      alarmsB,
      perms,
    );
    await areaB.replace(staging);

    expect(await areaB.afterRestore(), {RestoreNotice.alarmSoundFallback});
    expect(await areaB.afterRestore(), isEmpty);
  });

  test('afterRestore asks for permissions only when alarms exist', () async {
    when(() => perms.canRing()).thenAnswer((_) async => false);
    SharedPreferences.setMockInitialValues({});
    final empty = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      b,
      soundsB,
      alarmsB,
      perms,
    );
    expect(await empty.afterRestore(), isEmpty);

    await seedA();
    final withAlarms = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      b,
      soundsB,
      alarmsB,
      perms,
    );
    expect(await withAlarms.afterRestore(), {
      RestoreNotice.alarmPermissionNeeded,
    });
  });

  test('replace again after the sounds folder was moved keeps sounds and '
      'paths', () async {
    await seedA();
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    ).export(staging);
    SharedPreferences.setMockInitialValues({});
    final areaB = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      b,
      soundsB,
      alarmsB,
      perms,
    );
    await areaB.replace(staging);
    expect(Directory('${staging.path}/alarm/sounds').existsSync(), isFalse);

    await areaB.replace(staging);

    expect(File('${soundsB.path}/abc123.ogg').readAsBytesSync(), [1, 2, 3]);
    final restored = await alarmsOf(await SharedPreferences.getInstance());
    expect(
      restored[0].sound,
      AlarmSound.device(title: '오프닝', path: '${soundsB.path}/abc123.ogg'),
    );
    expect(await areaB.afterRestore(), isEmpty);
  });

  test('afterRestore reports a failed resync instead of throwing', () async {
    when(() => alarmsB.sync()).thenThrow(StateError('scheduler down'));
    final logs = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = original);
    SharedPreferences.setMockInitialValues({});
    final area = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      b,
      soundsB,
      alarmsB,
      perms,
    );

    expect(await area.afterRestore(), {RestoreNotice.alarmResyncFailed});
    expect(logs.single, contains('scheduler down'));
  });

  test('restore into device without alarm_sounds dir', () async {
    await seedA();
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    ).export(staging);

    // 새 기기: 문서 폴더조차 아직 없다.
    expect(soundsB.parent.existsSync(), isFalse);
    SharedPreferences.setMockInitialValues({});
    final prefsB = await SharedPreferences.getInstance();
    await AlarmBackupArea(prefsB, b, soundsB, alarmsB, perms).replace(staging);

    expect(File('${soundsB.path}/abc123.ogg').existsSync(), isTrue);
    expect((await alarmsOf(prefsB)), hasLength(3));
  });

  test('backup without alarms or sounds clears them on replace', () async {
    SharedPreferences.setMockInitialValues({});
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      Directory('${tmp.path}/a/none'),
      alarmsA,
      perms,
    ).export(staging);

    await seedA(); // 이번엔 B 쪽으로 쓴다
    final prefsB = await SharedPreferences.getInstance();
    await AlarmBackupArea(prefsB, a, soundsA, alarmsB, perms).replace(staging);

    expect(await alarmsOf(prefsB), isEmpty);
    expect(await a.select(a.archivedRings).get(), isEmpty);
    expect(soundsA.listSync(), isEmpty);
    for (final key in _otherAlarmPrefs.keys) {
      expect(prefsB.containsKey(key), isFalse, reason: key);
    }
  });

  test('keeps alarm items the serializer cannot read as they were', () async {
    SharedPreferences.setMockInitialValues({
      PrefsAlarmRepository.key: jsonEncode([
        {'broken': true},
        const Alarm(id: 4, hour: 6, minute: 0).toJson(),
      ]),
    });
    await AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    ).export(staging);

    SharedPreferences.setMockInitialValues({});
    final prefsB = await SharedPreferences.getInstance();
    await AlarmBackupArea(prefsB, b, soundsB, alarmsB, perms).replace(staging);

    final raw = jsonDecode(prefsB.getString(PrefsAlarmRepository.key)!) as List;
    expect(raw.first, {'broken': true});
    expect((await alarmsOf(prefsB)).single.id, 4);
  });

  test('afterRestore calls sync once', () async {
    SharedPreferences.setMockInitialValues({});
    final area = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      b,
      soundsB,
      alarmsB,
      perms,
    );

    await area.afterRestore();

    verify(() => alarmsB.sync()).called(1);
  });

  test('validate rejects missing or malformed ring_archive.json', () async {
    await seedA();
    final prefs = await SharedPreferences.getInstance();
    await AlarmBackupArea(prefs, a, soundsA, alarmsA, perms).export(staging);
    final areaB = AlarmBackupArea(prefs, b, soundsB, alarmsB, perms);
    expect(await _failureOf(() => areaB.validate(staging)), isNull);

    final file = File('${staging.path}/alarm/ring_archive.json');
    file.writeAsStringSync('{oops');
    expect(
      await _failureOf(() => areaB.validate(staging)),
      BackupFailure.integrity,
    );
    file.deleteSync();
    expect(
      await _failureOf(() => areaB.validate(staging)),
      BackupFailure.integrity,
    );
  });

  test('id, schema and estimatedBytes', () async {
    await seedA();
    final area = AlarmBackupArea(
      await SharedPreferences.getInstance(),
      a,
      soundsA,
      alarmsA,
      perms,
    );

    expect(area.id, BackupAreaId.alarm);
    expect(area.schema, {'ringArchive': 1, 'alarmsJson': 1});
    expect(await area.estimatedBytes(), 5);
  });
}
