import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/data/backup/area/drift_rows.dart';
import 'package:walk/data/backup/area/location_backup_area.dart';
import 'package:walk/data/location/database/location_database.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/restore_notice.dart';
import 'package:walk/domain/location/entity/record_mode.dart';
import 'package:walk/domain/location/recorder/location_recorder.dart';
import 'package:walk/domain/location/recorder/recorder_status.dart';

class _MockRecorder extends Mock implements LocationRecorder {}

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

Future<void> _point(LocationDatabase db, DateTime at, {bool still = false}) =>
    db
        .into(db.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            recordedAt: at,
            lat: 37.5,
            lng: 127.0 + at.minute / 1000,
            accuracyM: const Value(12.5),
            mode: RecordMode.values.first,
            stillStart: Value(still),
          ),
        );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory staging;
  late LocationDatabase a;
  late LocationDatabase b;
  late _MockRecorder recorder;

  setUp(() {
    recorder = _MockRecorder();
    when(recorder.status).thenAnswer((_) async => const RecorderStatus.off());
    tmp = Directory.systemTemp.createTempSync('location_backup_area_test');
    staging = Directory('${tmp.path}/staging')..createSync();
    a = LocationDatabase(NativeDatabase.memory());
    b = LocationDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await a.close();
    await b.close();
    tmp.deleteSync(recursive: true);
  });

  group('afterRestore tells to turn recording on only when it is off', () {
    for (final (status, notices) in [
      (const RecorderStatus.off(), {RestoreNotice.locationRecordingOff}),
      (
        RecorderStatus.running(RecordMode.values.first, stillDetection: true),
        <RestoreNotice>{},
      ),
      (RecorderStatus.blocked(RecordMode.values.first), <RestoreNotice>{}),
    ]) {
      test('$status', () async {
        when(recorder.status).thenAnswer((_) async => status);
        expect(await LocationBackupArea(b, recorder).afterRestore(), notices);
      });
    }

    test('status error still tells (cannot tell it is on)', () async {
      when(recorder.status).thenThrow(StateError('channel'));
      expect(await LocationBackupArea(b, recorder).afterRestore(), {
        RestoreNotice.locationRecordingOff,
      });
    });
  });

  test('location round trip', () async {
    await _point(a, DateTime(2026, 11, 1, 8, 0));
    await _point(a, DateTime(2026, 11, 1, 8, 5), still: true);
    await _point(a, DateTime(2026, 11, 1, 8, 10));
    await a
        .into(a.placeNames)
        .insert(
          PlaceNamesCompanion.insert(
            gridKey: '37.50:127.00',
            name: '회사',
            updatedAt: DateTime(2026, 11, 1),
          ),
        );
    final areaA = LocationBackupArea(a, recorder);

    final counts = await areaA.export(staging);
    expect(counts, {'points': 3});
    expect(await areaA.counts(), counts);

    await _point(b, DateTime(2026, 11, 16, 9));
    final areaB = LocationBackupArea(b, recorder);
    await areaB.validate(staging);
    await areaB.replace(staging);
    expect(await areaB.afterRestore(), {RestoreNotice.locationRecordingOff});

    for (final t in a.allTables) {
      expect(
        await dumpTable(b, t),
        await dumpTable(a, t),
        reason: t.actualTableName,
      );
    }
  });

  test('replace into empty DB from empty backup', () async {
    await LocationBackupArea(a, recorder).export(staging);
    await _point(b, DateTime(2026, 11, 16, 9));

    await LocationBackupArea(b, recorder).replace(staging);

    expect(await b.select(b.locationPoints).get(), isEmpty);
  });

  test('validate rejects missing or malformed data.json', () async {
    await LocationBackupArea(a, recorder).export(staging);
    final areaB = LocationBackupArea(b, recorder);
    final file = File('${staging.path}/location/data.json');

    file.writeAsStringSync('{"location_points": 1}');
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
    await _point(a, DateTime(2026, 11, 1, 8));
    final area = LocationBackupArea(a, recorder);

    expect(area.id, BackupAreaId.location);
    expect(area.schema, {'location': 1});
    expect(await area.estimatedBytes(), greaterThan(0));
  });
}
