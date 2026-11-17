import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/profile/prefs_profile_repository.dart';
import 'package:walk/data/alarm/archive/ring_archive_database.dart';
import 'package:walk/data/alarm/prefs_alarm_repository.dart';
import 'package:walk/data/backup/area/alarm_backup_area.dart';
import 'package:walk/data/backup/area/chat_backup_area.dart';
import 'package:walk/data/backup/area/diary_backup_area.dart';
import 'package:walk/data/backup/area/drift_rows.dart';
import 'package:walk/data/backup/area/location_backup_area.dart';
import 'package:walk/data/backup/area/settings_backup_area.dart';
import 'package:walk/data/backup/area/wiki_backup_area.dart';
import 'package:walk/data/backup/crypto/backup_cipher.dart';
import 'package:walk/data/backup/default_backup_service.dart';
import 'package:walk/data/backup/prefs_backup_preferences.dart';
import 'package:walk/data/chat/database/chat_database.dart';
import 'package:walk/data/location/database/location_database.dart';
import 'package:walk/domain/alarm/entity/alarm.dart';
import 'package:walk/domain/alarm/entity/alarm_sound.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';
import 'package:walk/domain/alarm/usecase/alarm_use_case.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_area_source.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/backup_service.dart';
import 'package:walk/domain/backup/restore_notice.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';

import '../../support/chat_db_seed.dart';
import '../../support/diary_fixtures.dart';

class _MockAlarmUseCase extends Mock implements AlarmUseCase {}

class _MockAlarmPermissions extends Mock implements AlarmPermissions {}

class _MockChatSettings extends Mock implements ChatSettings {}

class _MockLocationRecorder extends Mock implements LocationRecorder {}

final _now = DateTime(2026, 11, 16, 21, 30);
const _password = 'correct horse';

/// 허용 목록 밖의 비밀 값. 백업에도, 복원 결과에도 없어야 한다.
const _secretPrefs = <String, Object>{
  'chat.apiKey': 'sk-secret',
  'anthropic_api_key': 'sk-legacy',
  'chat.keyStatus': 'valid',
  'chat.consented': true,
  'chat.consentedVendor': 'anthropic',
  'chat.consentScope': 'records',
  'walk.lock.enabled': true,
};

/// 각 영역의 허용 목록에 든 prefs.
const _areaPrefs = <String, Object>{
  'walk.diary.trashRetention': 'day30',
  'walk.chat.retention': 'days30',
  'walk.chat.wikiIndexSize': 'large',
  'walk.holidayReminder': false,
  'walk.themeMode': 'dark',
  'walk.stepGoal': 8000,
  'walk.location.retention': 'days90',
};

/// `Failure.validation(field: name)` 인 [Err] 의 [BackupFailure].
BackupFailure? _failureOf(Result<Object?> r) => switch (r) {
  Err(failure: ValidationFailure(:final field?)) => BackupFailure.values.byName(
    field,
  ),
  _ => null,
};

T _ok<T>(Result<T> r) => okValue(r);

/// 앱 하나(문서 폴더 · DB · prefs). 같은 [docs] 경로로 다시 만들면 "앱 데이터 지운 뒤"다.
class _Device {
  _Device._(this.docs, this.cache, this.prefs, this.clock);

  static Future<_Device> open(
    Directory docs,
    Directory cache, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final device = _Device._(
      docs..createSync(recursive: true),
      cache..createSync(recursive: true),
      await SharedPreferences.getInstance(),
      MutableClock(_now),
    );
    when(() => device.alarms.sync()).thenAnswer((_) async {});
    when(() => device.permissions.canRing()).thenAnswer((_) async => true);
    when(() => device.chatSettings.hasApiKey()).thenAnswer((_) async => false);
    when(
      device.recorder.status,
    ).thenAnswer((_) async => const RecorderStatus.off());
    return device;
  }

  final Directory docs;
  final Directory cache;
  final SharedPreferences prefs;
  final MutableClock clock;
  final diary = DiaryHarness(now: _now);
  final chat = ChatDatabase(NativeDatabase.memory());
  final rings = RingArchiveDatabase(NativeDatabase.memory());
  final location = LocationDatabase(NativeDatabase.memory());
  final alarms = _MockAlarmUseCase();
  final permissions = _MockAlarmPermissions();
  final chatSettings = _MockChatSettings();
  final recorder = _MockLocationRecorder();

  Directory get diaryRoot => Directory('${docs.path}/diary');
  Directory get workspace => Directory('${docs.path}/workspace');
  Directory get sounds => Directory('${docs.path}/alarm_sounds');

  late final realAreas = <BackupAreaSource>[
    DiaryBackupArea(diary.db, diaryRoot, prefs),
    ChatBackupArea(chat, workspace, prefs, chatSettings),
    WikiBackupArea(chat, prefs),
    AlarmBackupArea(prefs, rings, sounds, alarms, permissions),
    SettingsBackupArea(
      prefs,
      PrefsProfileRepository.withEncoder(
        prefs,
        docs,
        encode: (src, dst) async => File(src).copy(dst),
      ),
    ),
    LocationBackupArea(location, recorder),
  ];

  DefaultBackupService service({
    List<BackupAreaSource>? areas,
    Future<int?> Function()? freeBytes,
    Future<void> Function(Directory dir)? deleteTree,
    BackupCipher? cipher,
  }) => DefaultBackupService(
    areas: areas ?? realAreas,
    appDocs: docs,
    cache: cache,
    appVersion: '1.0.0+1',
    clock: clock,
    cipher: cipher ?? BackupCipher(iterations: 1000),
    freeBytes: freeBytes,
    deleteTree: deleteTree,
  );

  Future<void> close() async {
    await diary.close();
    await chat.close();
    await rings.close();
    await location.close();
  }

  /// 여섯 영역 모두에 데이터를 넣는다.
  Future<void> seed() async {
    okValue(
      await diary.repository.createEntry(
        entryDraft(body: '바다', media: [photoMedia('p1')], tags: ['여행']),
      ),
    );
    _writeFile(diaryRoot, 'media/p1.jpg', [1, 2, 3]);

    await insertConversation(chat, 'c1');
    await insertTurn(chat, 'c1', 1);
    _writeFile(workspace, 'inbox/note.txt', utf8.encode('첨부'));
    await insertWikiNote(chat, 1, source: 'c1');

    _writeFile(sounds, 'abc.ogg', [7, 7]);
    await prefs.setString(
      PrefsAlarmRepository.key,
      jsonEncode([
        Alarm(
          id: 1,
          hour: 7,
          minute: 0,
          sound: AlarmSound.device(
            title: '오프닝',
            path: '${sounds.path}/abc.ogg',
          ),
        ).toJson(),
      ]),
    );
    await rings
        .into(rings.archivedRings)
        .insert(
          ArchivedRingsCompanion.insert(
            at: DateTime(2026, 11, 1, 7),
            packageId: 300,
            kind: RingLogKind.stopped,
          ),
        );

    await addPoint(DateTime(2026, 11, 1, 9));
  }

  Future<void> addPoint(DateTime at) => location
      .into(location.locationPoints)
      .insert(
        LocationPointsCompanion.insert(
          recordedAt: at,
          lat: 37.5,
          lng: 127,
          accuracyM: const Value(10),
          mode: RecordMode.values.first,
        ),
      );

  /// 모든 테이블 행 · 파일 바이트 · prefs. 마지막 백업 시각은 뺀다.
  Future<Map<String, Object?>> snapshot() async => {
    for (final t in diary.db.allTables)
      'diary.${t.actualTableName}': await dumpTable(diary.db, t),
    for (final t in chat.allTables)
      'chat.${t.actualTableName}': await dumpTable(chat, t),
    for (final t in rings.allTables)
      'rings.${t.actualTableName}': await dumpTable(rings, t),
    for (final t in location.allTables)
      'location.${t.actualTableName}': await dumpTable(location, t),
    'files': _files(docs),
    'prefs': {
      for (final k in prefs.getKeys())
        if (k != PrefsBackupPreferences.lastAtKey) k: prefs.get(k),
    },
  };
}

void _writeFile(Directory dir, String relative, List<int> bytes) =>
    File('${dir.path}/$relative')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

/// 데이터 폴더(diary · workspace · alarm_sounds)의 파일 → 바이트.
Map<String, List<int>> _files(Directory docs) => {
  for (final name in ['diary', 'workspace', 'alarm_sounds'])
    if (Directory('${docs.path}/$name').existsSync())
      for (final f in Directory(
        '${docs.path}/$name',
      ).listSync(recursive: true)..sort((a, b) => a.path.compareTo(b.path)))
        if (f is File) f.path.substring(docs.path.length): f.readAsBytesSync(),
};

/// 이름이 [match] 에 맞는 폴더를 지우다 [victim] 파일 하나만 지운 채 죽는(던지는) `deleteTree`.
/// 한 번만 죽고 그다음부터는 그냥 지운다.
Future<void> Function(Directory) _crashWhileDeleting(
  bool Function(String name) match,
  String victim,
) {
  var crashed = false;
  return (dir) async {
    final name = dir.path.split('/').last;
    if (!crashed && match(name)) {
      crashed = true;
      final f = File('${dir.path}/$victim');
      if (f.existsSync()) f.deleteSync();
      throw StateError('process died while deleting $name');
    }
    await dir.delete(recursive: true);
  };
}

/// 다른 isolate 로 보낼 수 없는 것(ReceivePort)을 쥔 진행 받이.
class _UnsendableHolder {
  final port = ReceivePort();
  final steps = <double>[];
}

/// 부른 isolate 에서 무엇을 불렀는지 남기는 암호. 다른 isolate 로 보내면 사본에 남아 비어 있다.
class _RecordingCipher extends BackupCipher {
  _RecordingCipher() : super(iterations: 1000);

  final calls = <String>[];

  @override
  Future<void> encrypt(
    File plain,
    File out,
    String password, {
    void Function(double fraction)? onProgress,
  }) {
    calls.add('encrypt');
    return super.encrypt(plain, out, password, onProgress: onProgress);
  }

  @override
  Future<void> decrypt(
    File sealed,
    File out,
    String password, {
    void Function(double fraction)? onProgress,
  }) {
    calls.add('decrypt');
    return super.decrypt(sealed, out, password, onProgress: onProgress);
  }
}

/// 메모리에만 값을 두는 가짜 영역. 파일은 `root/<id>/value.txt` 하나.
class _FakeArea implements BackupAreaSource {
  _FakeArea(this.id, this.log, {this.schema = const {'fake': 1}});

  @override
  final BackupAreaId id;

  @override
  final Map<String, int> schema;

  final List<String> log;
  String value = 'initial';

  /// 다음 [replace] 한 번이 아무것도 바꾸기 전에 실패한다.
  bool failReplace = false;

  /// [replace] 가 값을 바꾼 뒤 차례로 던질 오류(반쯤 바꾸고 실패 흉내).
  final errorsAfterChange = <Object>[];

  /// 있으면 [afterRestore] 가 던진다.
  Object? afterRestoreError;
  Set<RestoreNotice> notices = const {};

  /// 있으면 [replace] 가 들어오자마자 완료하고 [hang] 을 기다린다(도중 종료 흉내).
  Completer<void>? entered;
  final hang = Completer<void>();

  File _file(Directory root) => File('${root.path}/${id.name}/value.txt');

  @override
  Future<Map<String, int>> counts() async => {'n': 1};

  @override
  Future<int> estimatedBytes() async => 10;

  @override
  Future<Map<String, int>> export(Directory root) async {
    _file(root)
      ..createSync(recursive: true)
      ..writeAsStringSync(value);
    return {'n': 1};
  }

  @override
  Future<void> validate(Directory root) async {
    if (!_file(root).existsSync()) {
      throw const BackupException(BackupFailure.integrity);
    }
  }

  @override
  Future<void> replace(Directory root) async {
    log.add('replace:${id.name}');
    if (entered case final c?) {
      c.complete();
      await hang.future;
    }
    if (failReplace) {
      failReplace = false;
      throw StateError('replace failed');
    }
    value = _file(root).readAsStringSync();
    if (errorsAfterChange.isNotEmpty) throw errorsAfterChange.removeAt(0);
  }

  @override
  Future<Set<RestoreNotice>> afterRestore() async {
    log.add('after:${id.name}');
    if (afterRestoreError case final e?) throw e;
    return notices;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory docs;
  late Directory cache;
  final opened = <_Device>[];

  Future<_Device> device({Map<String, Object> prefs = const {}}) async {
    final d = await _Device.open(docs, cache, prefs: prefs);
    opened.add(d);
    return d;
  }

  /// 서비스가 [debugPrint] 로 남긴 줄(테스트 출력을 깨끗하게 둔다).
  final logs = <String?>[];
  final originalDebugPrint = debugPrint;

  setUp(() {
    logs.clear();
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = originalDebugPrint);
    tmp = Directory.systemTemp.createTempSync('default_backup_service_test');
    docs = Directory('${tmp.path}/app_flutter');
    cache = Directory('${tmp.path}/cache');
  });

  tearDown(() async {
    for (final d in opened) {
      await d.close();
    }
    opened.clear();
    tmp.deleteSync(recursive: true);
  });

  Directory staging() => Directory('${docs.path}/restore_staging');
  Directory undoDir() => Directory('${docs.path}/restore_undo');

  for (final encrypted in [false, true]) {
    test('full export → wipe → inspect → restore round trip, '
        '${encrypted ? 'encrypted' : 'plain'}', () async {
      final a = await device(prefs: {..._areaPrefs, ..._secretPrefs});
      await a.seed();
      final before = await a.snapshot();
      final file = _ok(
        await a.service().export(
          BackupAreaId.values.toSet(),
          password: encrypted ? _password : null,
        ),
      );
      expect(
        file.path.split('/').last,
        encrypted
            ? 'lifelog-backup-20261116-2130.lifelog'
            : 'lifelog-backup-20261116-2130.zip',
      );
      expect(file.parent.path, startsWith(cache.path));

      // 앱 데이터 지우기: 문서 폴더 · DB · prefs 가 새것이다. 캐시의 백업 파일만 남는다.
      await a.close();
      opened.remove(a);
      docs.deleteSync(recursive: true);
      final b = await device();
      final service = b.service();

      final inspected = _ok(
        await service.inspect(file, password: encrypted ? _password : null),
      );
      expect(inspected.manifest.appVersion, '1.0.0+1');
      expect(inspected.areas, {
        for (final id in BackupAreaId.values) id: AreaAvailability.ok,
      });
      expect(inspected.manifest.areas[BackupAreaId.diary]!.counts, {
        'entries': 1,
        'media': 1,
      });

      final notices = _ok(
        await service.restore(inspected, BackupAreaId.values.toSet()),
      );

      expect(notices, {
        RestoreNotice.locationRecordingOff,
        RestoreNotice.apiKeyNeeded,
      });
      final after = await b.snapshot();
      final expected = {
        ...before,
        'prefs': {
          for (final e in (before['prefs']! as Map<String, Object?>).entries)
            if (!_secretPrefs.containsKey(e.key)) e.key: e.value,
        },
      };
      expect(after, expected);
      expect((after['diary.entries']! as List), hasLength(1));
      expect(staging().existsSync(), isFalse);
      verify(() => b.alarms.sync()).called(1);
    });
  }

  test('restoring subset leaves other areas untouched', () async {
    final d = await device(prefs: _areaPrefs);
    await d.seed();
    final service = d.service();
    final file = _ok(await service.export(BackupAreaId.values.toSet()));
    final backedUp = await d.snapshot();

    okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
    await d.addPoint(DateTime(2026, 11, 2, 9));
    await d.prefs.setString('walk.themeMode', 'light');
    final changed = await d.snapshot();

    final inspected = _ok(await service.inspect(file));
    final notices = _ok(await service.restore(inspected, {BackupAreaId.diary}));

    expect(notices, isEmpty);
    final after = await d.snapshot();
    expect(after['diary.entries'], backedUp['diary.entries']);
    expect(
      after['location.location_points'],
      changed['location.location_points'],
    );
    expect((after['location.location_points']! as List), hasLength(2));
    expect((after['prefs']! as Map)['walk.themeMode'], 'light');
  });

  test('restore runs areas in BackupAreaId order', () async {
    final d = await device();
    final log = <String>[];
    // 일부러 거꾸로 넘긴다.
    final fakes = [
      for (final id in BackupAreaId.values.reversed) _FakeArea(id, log),
    ];
    fakes.first.notices = {RestoreNotice.locationRecordingOff};
    fakes.last.notices = {RestoreNotice.apiKeyNeeded};
    final service = d.service(areas: fakes);
    final file = _ok(await service.export(BackupAreaId.values.toSet()));
    final inspected = _ok(await service.inspect(file));
    log.clear();

    final notices = _ok(
      await service.restore(inspected, BackupAreaId.values.toSet()),
    );

    expect(log, [
      for (final id in BackupAreaId.values) 'replace:${id.name}',
      for (final id in BackupAreaId.values) 'after:${id.name}',
    ]);
    expect(notices, {
      RestoreNotice.locationRecordingOff,
      RestoreNotice.apiKeyNeeded,
    });
  });

  test('failure in second area rolls back first area', () async {
    final d = await device();
    await d.seed();
    final log = <String>[];
    final chat = _FakeArea(BackupAreaId.chat, log);
    final service = d.service(areas: [d.realAreas.first, chat]);
    final file = _ok(
      await service.export({BackupAreaId.diary, BackupAreaId.chat}),
    );

    okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
    _writeFile(d.diaryRoot, 'media/later.jpg', [5]);
    final beforeRestore = await d.snapshot();
    chat
      ..value = 'changed'
      ..failReplace = true;

    final inspected = _ok(await service.inspect(file));
    final result = await service.restore(inspected, {
      BackupAreaId.diary,
      BackupAreaId.chat,
    });

    expect(result, isA<Err<Set<RestoreNotice>>>());
    expect(await d.snapshot(), beforeRestore);
    expect(chat.value, 'changed');
    expect(log.where((l) => l.startsWith('after')), isEmpty);
    expect(await service.hasUndoPoint(), isFalse);
    expect(staging().existsSync(), isFalse);
    expect(undoDir().existsSync(), isFalse);
  });

  test(
    'area that changed its data and then failed is rolled back too',
    () async {
      final d = await device();
      await d.seed();
      final log = <String>[];
      final chat = _FakeArea(BackupAreaId.chat, log);
      final service = d.service(areas: [d.realAreas.first, chat]);
      final file = _ok(
        await service.export({BackupAreaId.diary, BackupAreaId.chat}),
      );
      okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
      final beforeRestore = await d.snapshot();
      chat
        ..value = 'changed'
        ..errorsAfterChange.add(StateError('prefs write failed'));

      final inspected = _ok(await service.inspect(file));
      final result = await service.restore(inspected, {
        BackupAreaId.diary,
        BackupAreaId.chat,
      });

      expect(_failureOf(result), BackupFailure.io);
      expect(chat.value, 'changed');
      expect(await d.snapshot(), beforeRestore);
      expect(await service.needsRecovery(), isFalse);
      expect(undoDir().existsSync(), isFalse);
    },
  );

  test(
    'failed rollback keeps the original failure and the recovery marker',
    () async {
      final d = await device();
      await d.seed();
      final log = <String>[];
      final chat = _FakeArea(BackupAreaId.chat, log);
      final service = d.service(areas: [d.realAreas.first, chat]);
      final file = _ok(
        await service.export({BackupAreaId.diary, BackupAreaId.chat}),
      );
      okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
      final beforeRestore = await d.snapshot();
      chat
        ..value = 'changed'
        ..errorsAfterChange.addAll([
          const BackupException(BackupFailure.integrity),
          StateError('rollback failed too'),
        ]);

      final inspected = _ok(await service.inspect(file));
      final result = await service.restore(inspected, {
        BackupAreaId.diary,
        BackupAreaId.chat,
      });

      expect(_failureOf(result), BackupFailure.integrity);
      expect(await service.needsRecovery(), isTrue);
      expect(await service.hasUndoPoint(), isFalse);

      // 다음 시작: 이번에는 되돌리기가 된다.
      await service.recoverIfInterrupted();
      expect(await service.needsRecovery(), isFalse);
      expect(chat.value, 'changed');
      expect(await d.snapshot(), beforeRestore);
    },
  );

  test('restore with no areas is a no-op that keeps the undo point', () async {
    final d = await device();
    await d.seed();
    final service = d.service();
    final file = _ok(await service.export({BackupAreaId.location}));
    _ok(
      await service.restore(_ok(await service.inspect(file)), {
        BackupAreaId.location,
      }),
    );
    expect(await service.hasUndoPoint(), isTrue);

    final inspected = _ok(await service.inspect(file));
    expect(_ok(await service.restore(inspected, {})), isEmpty);

    expect(await service.hasUndoPoint(), isTrue);
    expect(await service.needsRecovery(), isFalse);
  });

  test('afterRestore failure does not fail the restore', () async {
    final d = await device();
    final log = <String>[];
    final diary = _FakeArea(BackupAreaId.diary, log)
      ..afterRestoreError = StateError('boom');
    final chat = _FakeArea(BackupAreaId.chat, log)
      ..notices = {RestoreNotice.apiKeyNeeded};
    final service = d.service(areas: [diary, chat]);
    final file = _ok(
      await service.export({BackupAreaId.diary, BackupAreaId.chat}),
    );

    final notices = _ok(
      await service.restore(_ok(await service.inspect(file)), {
        BackupAreaId.diary,
        BackupAreaId.chat,
      }),
    );

    expect(notices, {RestoreNotice.apiKeyNeeded});
    expect(logs.single, contains('afterRestore of diary failed'));
  });

  test('backup with empty files folders clears them through the zip', () async {
    final d = await device();
    final service = d.service();
    // 미디어 · 작업 폴더 · 알람음이 하나도 없을 때 만든 백업.
    final file = _ok(
      await service.export({
        BackupAreaId.diary,
        BackupAreaId.chat,
        BackupAreaId.alarm,
      }),
    );
    _writeFile(d.diaryRoot, 'media/later.jpg', [5]);
    _writeFile(d.workspace, 'out/later.md', [6]);
    _writeFile(d.sounds, 'later.ogg', [7]);

    _ok(
      await service.restore(_ok(await service.inspect(file)), {
        BackupAreaId.diary,
        BackupAreaId.chat,
        BackupAreaId.alarm,
      }),
    );

    expect(_files(docs), isEmpty);
  });

  test(
    'startup replay after a crash mid-recovery keeps pre-restore media',
    () async {
      final d = await device();
      await d.seed();
      final log = <String>[];
      final hanging = _FakeArea(BackupAreaId.chat, log)
        ..entered = Completer<void>();
      final service = d.service(areas: [d.realAreas.first, hanging]);
      final file = _ok(
        await service.export({BackupAreaId.diary, BackupAreaId.chat}),
      );
      okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
      _writeFile(d.diaryRoot, 'media/later.jpg', [5]);
      final beforeRestore = await d.snapshot();

      final inspected = _ok(await service.inspect(file));
      unawaited(
        service.restore(inspected, {BackupAreaId.diary, BackupAreaId.chat}),
      );
      await hanging.entered!.future;

      // 첫 시작 복구가 일기 미디어를 옮긴 뒤(되돌리기 폴더를 지우기 전) 죽었다.
      await d.realAreas.first.replace(undoDir());
      expect(Directory('${undoDir().path}/diary').existsSync(), isTrue);

      final restarted = d.service(
        areas: [d.realAreas.first, _FakeArea(BackupAreaId.chat, log)],
      );
      await restarted.recoverIfInterrupted();

      expect(await d.snapshot(), beforeRestore);
      expect(await restarted.needsRecovery(), isFalse);
    },
  );

  test('recovers interrupted restore on startup', () async {
    final d = await device();
    await d.seed();
    final log = <String>[];
    final hanging = _FakeArea(BackupAreaId.chat, log)
      ..entered = Completer<void>();
    final service = d.service(areas: [d.realAreas.first, hanging]);
    final file = _ok(
      await service.export({BackupAreaId.diary, BackupAreaId.chat}),
    );
    okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
    _writeFile(d.diaryRoot, 'media/later.jpg', [5]);
    final beforeRestore = await d.snapshot();

    final inspected = _ok(await service.inspect(file));
    // 일기를 바꾼 뒤 대화 영역에서 멈춘다(앱이 죽은 것으로 본다).
    unawaited(
      service.restore(inspected, {BackupAreaId.diary, BackupAreaId.chat}),
    );
    await hanging.entered!.future;
    expect((await d.snapshot())['diary.entries'], hasLength(1));

    // 다시 시작한 앱.
    final restarted = d.service(
      areas: [d.realAreas.first, _FakeArea(BackupAreaId.chat, log)],
    );
    await restarted.recoverIfInterrupted();

    expect(await d.snapshot(), beforeRestore);
    expect(staging().existsSync(), isFalse);
    expect(undoDir().existsSync(), isFalse);
    expect(await restarted.hasUndoPoint(), isFalse);
  });

  group('crash while deleting undo folders', () {
    /// 설정 · 위치를 백업하고 바꾼 뒤 복원까지 마친 기기. 돌려주는 값은 복원 전 상태.
    Future<(_Device, Map<String, Object?>)> restored() async {
      final d = await device(prefs: _areaPrefs);
      await d.seed();
      final service = d.service();
      final file = _ok(
        await service.export({BackupAreaId.settings, BackupAreaId.location}),
      );
      await d.prefs.setString('walk.themeMode', 'light');
      await d.addPoint(DateTime(2026, 11, 2, 9));
      final beforeRestore = await d.snapshot();
      _ok(
        await service.restore(_ok(await service.inspect(file)), {
          BackupAreaId.settings,
          BackupAreaId.location,
        }),
      );
      expect(await d.snapshot(), isNot(beforeRestore));
      return (d, beforeRestore);
    }

    for (final (area, victim) in [
      ('settings', 'prefs.json'),
      ('location', 'data.json'),
    ]) {
      test(
        'half-deleted replayed $area folder is not replayed again',
        () async {
          final (d, beforeRestore) = await restored();
          final crashing = d.service(
            deleteTree: _crashWhileDeleting((n) => n.contains(area), victim),
          );
          await crashing.undo();

          final restarted = d.service();
          await restarted.recoverIfInterrupted();

          expect(await restarted.needsRecovery(), isFalse);
          expect(await d.snapshot(), beforeRestore);
          expect(undoDir().existsSync(), isFalse);
        },
      );
    }

    test(
      'half-deleted undo point after undo leaves no stale undo point',
      () async {
        final (d, beforeRestore) = await restored();
        final crashing = d.service(
          deleteTree: _crashWhileDeleting(
            (n) => n.startsWith('restore_undo'),
            'in_progress.json',
          ),
        );
        await crashing.undo();

        final restarted = d.service();
        await restarted.recoverIfInterrupted();

        expect(await restarted.hasUndoPoint(), isFalse);
        expect(await restarted.needsRecovery(), isFalse);
        expect(await d.snapshot(), beforeRestore);
        expect(
          docs.listSync().map((e) => e.path.split('/').last),
          isNot(contains(startsWith('restore_undo'))),
        );
      },
    );

    test('half-deleted previous undo point never wedges a new one', () async {
      final (d, _) = await restored();
      final file = _ok(
        await d.service().export({
          BackupAreaId.settings,
          BackupAreaId.location,
        }),
      );
      final crashing = d.service(
        deleteTree: _crashWhileDeleting(
          (n) => n.startsWith('restore_undo'),
          'location/data.json',
        ),
      );
      await crashing.restore(_ok(await crashing.inspect(file)), {
        BackupAreaId.settings,
        BackupAreaId.location,
      });

      final restarted = d.service();
      await restarted.recoverIfInterrupted();
      if (await restarted.hasUndoPoint()) _ok(await restarted.undo());

      expect(await restarted.needsRecovery(), isFalse);
    });

    test(
      'an undeletable leftover trash never blocks restore or undo',
      () async {
        final d = await device(prefs: _areaPrefs);
        await d.seed();
        // 지울 수 없는 버린 폴더가 남아 있다(권한 문제 등).
        Directory(
          '${docs.path}/restore_undo.trash/settings',
        ).createSync(recursive: true);
        Future<void> stubborn(Directory dir) async {
          if (dir.path.split('/').last.contains('trash')) {
            throw const FileSystemException('busy');
          }
          await dir.delete(recursive: true);
        }

        final service = d.service(deleteTree: stubborn);
        final file = _ok(
          await service.export({BackupAreaId.settings, BackupAreaId.location}),
        );
        await d.prefs.setString('walk.themeMode', 'light');
        final beforeRestore = await d.snapshot();
        for (var i = 0; i < 2; i++) {
          _ok(
            await service.restore(_ok(await service.inspect(file)), {
              BackupAreaId.settings,
              BackupAreaId.location,
            }),
          );
          _ok(await service.undo());
          expect(await d.snapshot(), beforeRestore);
        }
      },
    );

    test(
      'unreadable undo area is skipped so recovery still finishes',
      () async {
        final d = await device(prefs: _areaPrefs);
        await d.seed();
        final location = d.realAreas.last;
        final pointsBefore = (await d.snapshot())['location.location_points'];
        // 복원 도중 죽은 모양: 위치는 되돌리기 지점이 온전하고, 일기 폴더는 깨졌다.
        await location.export(undoDir());
        Directory('${undoDir().path}/diary').createSync(recursive: true);
        File('${undoDir().path}/in_progress.json').writeAsStringSync(
          jsonEncode({
            'areas': ['diary', 'location'],
          }),
        );
        await d.addPoint(DateTime(2026, 11, 2, 9));
        final diaryBefore = (await d.snapshot())['diary.entries'];

        final service = d.service();
        await service.recoverIfInterrupted();

        expect(await service.needsRecovery(), isFalse);
        final after = await d.snapshot();
        expect(after['location.location_points'], pointsBefore);
        expect(after['diary.entries'], diaryBefore);
        expect(logs.join('\n'), contains('diary'));
        expect(undoDir().existsSync(), isFalse);
      },
    );
  });

  test('startup recovery runs afterRestore for the replayed areas', () async {
    final d = await device();
    final log = <String>[];
    final diary = _FakeArea(BackupAreaId.diary, log);
    final hanging = _FakeArea(BackupAreaId.alarm, log)
      ..entered = Completer<void>();
    final service = d.service(areas: [diary, hanging]);
    final file = _ok(
      await service.export({BackupAreaId.diary, BackupAreaId.alarm}),
    );
    unawaited(
      service.restore(_ok(await service.inspect(file)), {
        BackupAreaId.diary,
        BackupAreaId.alarm,
      }),
    );
    await hanging.entered!.future;
    log.clear();

    final restarted = d.service(
      areas: [diary, _FakeArea(BackupAreaId.alarm, log)],
    );
    await restarted.recoverIfInterrupted();

    expect(log, [
      'replace:diary',
      'replace:alarm',
      'after:diary',
      'after:alarm',
    ]);
  });

  test('recoverIfInterrupted without a marker only clears staging', () async {
    final d = await device();
    await d.seed();
    final service = d.service();
    final file = _ok(await service.export({BackupAreaId.diary}));
    _ok(await service.inspect(file));
    final before = await d.snapshot();
    expect(staging().existsSync(), isTrue);

    await service.recoverIfInterrupted();

    expect(staging().existsSync(), isFalse);
    expect(await d.snapshot(), before);
  });

  test('undo of a chat-only restore brings wiki provenance back', () async {
    final d = await device();
    await d.seed();
    final service = d.service();
    final file = _ok(await service.export({BackupAreaId.chat}));
    await insertConversation(d.chat, 'x');
    await insertWikiNote(d.chat, 2, source: 'x');
    final beforeRestore = await d.snapshot();

    _ok(
      await service.restore(_ok(await service.inspect(file)), {
        BackupAreaId.chat,
      }),
    );
    expect(await d.snapshot(), isNot(beforeRestore));
    _ok(await service.undo());

    expect(await d.snapshot(), beforeRestore);
  });

  test('undo returns to pre-restore state', () async {
    final d = await device(prefs: _areaPrefs);
    await d.seed();
    final service = d.service();
    final file = _ok(await service.export(BackupAreaId.values.toSet()));

    okValue(await d.diary.repository.createEntry(entryDraft(body: '나중 기록')));
    _writeFile(d.diaryRoot, 'media/later.jpg', [5]);
    _writeFile(d.workspace, 'out/later.md', [6]);
    await d.addPoint(DateTime(2026, 11, 2, 9));
    await d.prefs.setInt('walk.stepGoal', 12000);
    final beforeRestore = await d.snapshot();
    expect(await service.hasUndoPoint(), isFalse);

    final inspected = _ok(await service.inspect(file));
    _ok(await service.restore(inspected, BackupAreaId.values.toSet()));
    expect(await service.hasUndoPoint(), isTrue);
    expect(await d.snapshot(), isNot(beforeRestore));

    final notices = _ok(await service.undo());

    expect(notices, contains(RestoreNotice.locationRecordingOff));
    expect(await d.snapshot(), beforeRestore);
    expect(await service.hasUndoPoint(), isFalse);
    expect(undoDir().existsSync(), isFalse);
    expect(await service.undo(), isA<Err<Set<RestoreNotice>>>());
  });

  test(
    'newer area schema marks area newerSchema and restore refuses it',
    () async {
      final d = await device();
      final log = <String>[];
      final newer = d.service(
        areas: [
          _FakeArea(BackupAreaId.diary, log),
          _FakeArea(BackupAreaId.chat, log, schema: const {'fake': 2}),
        ],
      );
      final file = _ok(
        await newer.export({BackupAreaId.diary, BackupAreaId.chat}),
      );

      final diary = _FakeArea(BackupAreaId.diary, log)..value = 'mine';
      final chat = _FakeArea(BackupAreaId.chat, log)..value = 'mine';
      final service = d.service(areas: [diary, chat]);
      final inspected = _ok(await service.inspect(file));

      expect(inspected.areas, {
        BackupAreaId.diary: AreaAvailability.ok,
        BackupAreaId.chat: AreaAvailability.newerSchema,
      });
      final refused = await service.restore(inspected, {
        BackupAreaId.diary,
        BackupAreaId.chat,
      });
      expect(_failureOf(refused), BackupFailure.newerAreaSchema);
      expect(diary.value, 'mine');
      expect(chat.value, 'mine');
      expect(await service.hasUndoPoint(), isFalse);

      final again = _ok(await service.inspect(file));
      _ok(await service.restore(again, {BackupAreaId.diary}));
      expect(diary.value, 'initial');
      expect(chat.value, 'mine');
    },
  );

  test(
    'cipher runs on the calling isolate (platform crypto lives there)',
    () async {
      final d = await device();
      await d.seed();
      final cipher = _RecordingCipher();
      final service = d.service(cipher: cipher);

      final file = _ok(
        await service.export({BackupAreaId.diary}, password: _password),
      );
      await service.discard(
        _ok(await service.inspect(file, password: _password)),
      );

      expect(cipher.calls, ['encrypt', 'decrypt']);
    },
  );

  for (final encrypted in [false, true]) {
    test('export and inspect report progress up to 1 '
        '(${encrypted ? 'encrypted' : 'plain'})', () async {
      final d = await device();
      await d.seed();
      final service = d.service();
      final password = encrypted ? _password : null;

      final exporting = <double>[];
      final file = _ok(
        await service.export(
          BackupAreaId.values.toSet(),
          password: password,
          onProgress: exporting.add,
        ),
      );
      final inspecting = <double>[];
      _ok(
        await service.inspect(
          file,
          password: password,
          onProgress: inspecting.add,
        ),
      );

      for (final steps in [exporting, inspecting]) {
        expect(steps.length, greaterThan(2));
        expect(steps, orderedEquals([...steps]..sort()));
        expect(steps.first, greaterThanOrEqualTo(0));
        expect(steps.last, 1.0);
      }
    });
  }

  test('progress callback that holds unsendable state still works '
      '(it never crosses into the zip isolate)', () async {
    final d = await device();
    await d.seed();
    final service = d.service();
    // 실제 화면의 onProgress 는 cubit → 서비스 → drift DB(ReceivePort)를 잡는다.
    final holder = _UnsendableHolder();
    addTearDown(holder.port.close);
    void onProgress(double f) => holder.steps.add(f);

    for (final password in [null, _password]) {
      final file = _ok(
        await service.export(
          BackupAreaId.values.toSet(),
          password: password,
          onProgress: onProgress,
        ),
      );
      _ok(
        await service.inspect(file, password: password, onProgress: onProgress),
      );
    }
    expect(holder.steps.last, 1.0);
  });

  test('wrong password → wrongPasswordOrCorrupt, data untouched', () async {
    final d = await device(prefs: _areaPrefs);
    await d.seed();
    final service = d.service();
    final file = _ok(
      await service.export(BackupAreaId.values.toSet(), password: _password),
    );
    final before = await d.snapshot();

    expect(
      _failureOf(await service.inspect(file, password: 'wrong password')),
      BackupFailure.wrongPasswordOrCorrupt,
    );
    expect(
      _failureOf(await service.inspect(file)),
      BackupFailure.wrongPasswordOrCorrupt,
    );
    expect(staging().existsSync(), isFalse);
    expect(await d.snapshot(), before);
  });

  test('not a backup file → notBackup', () async {
    final d = await device();
    final junk = File('${tmp.path}/junk.txt')..writeAsStringSync('hello');

    expect(
      _failureOf(await d.service().inspect(junk)),
      BackupFailure.notBackup,
    );
    expect(staging().existsSync(), isFalse);
  });

  test('backup contains no secret keys', () async {
    final d = await device(prefs: {..._areaPrefs, ..._secretPrefs});
    await d.seed();
    final file = _ok(await d.service().export(BackupAreaId.values.toSet()));

    final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    final jsonNames = [
      for (final f in archive)
        if (f.isFile && f.name.endsWith('.json')) f.name,
    ];
    expect(jsonNames, containsAll(['manifest.json', 'settings/prefs.json']));
    for (final name in jsonNames) {
      final text = utf8.decode(archive.find(name)!.readBytes()!);
      for (final secret in [
        'apiKey',
        'api_key',
        'walk.lock',
        'consented',
        'keyStatus',
      ]) {
        expect(text, isNot(contains(secret)), reason: '$name has $secret');
      }
    }
  });

  test('noSpace when freeBytes too small', () async {
    final d = await device();
    await d.seed();
    final ok = d.service();
    // 내보내기마다 캐시의 지난 파일을 지우므로 밖으로 옮겨 둔다(화면은 곧바로 사용자 위치로 저장한다).
    final file = _ok(
      await ok.export(BackupAreaId.values.toSet()),
    ).copySync('${tmp.path}/backup.zip');
    final tight = d.service(freeBytes: () async => 1);

    expect(
      _failureOf(await tight.export(BackupAreaId.values.toSet())),
      BackupFailure.noSpace,
    );
    expect(_failureOf(await tight.inspect(file)), BackupFailure.noSpace);
    expect(staging().existsSync(), isFalse);

    // 백업 크기의 2배까지는 받아들인다.
    final enough = d.service(freeBytes: () async => file.lengthSync() * 2);
    final inspected = _ok(await enough.inspect(file));
    await enough.discard(inspected);
    expect(staging().existsSync(), isFalse);
  });

  test(
    'export does not write lastAt — the screen records it after saving',
    () async {
      final d = await device();
      final prefs = PrefsBackupPreferences(d.prefs);
      final areas = [_FakeArea(BackupAreaId.diary, <String>[])];

      _ok(await d.service(areas: areas).export({BackupAreaId.diary}));

      expect(prefs.lastAt, isNull);
    },
  );

  test('preview gives counts and bytes per area', () async {
    final d = await device();
    await d.seed();

    final preview = await d.service().preview();

    expect(preview.keys, BackupAreaId.values);
    expect(preview[BackupAreaId.diary]!.counts, {'entries': 1, 'media': 1});
    expect(preview[BackupAreaId.alarm]!.bytes, 2);
    expect(preview[BackupAreaId.location]!.counts, {'points': 1});
  });
}
