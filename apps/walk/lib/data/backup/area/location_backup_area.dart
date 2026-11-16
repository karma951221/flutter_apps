import 'dart:io';

import 'package:drift/drift.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../../domain/location/recorder/location_recorder.dart';
import '../../../domain/location/recorder/recorder_status.dart';
import '../../location/database/location_database.dart';
import 'area_io.dart';
import 'drift_rows.dart';

const _dataFile = 'data.json';

/// JSON 으로 옮긴 이동 점 한 행의 대략 크기(날짜 문자열 · 좌표 · 정확도 · 모드).
const _bytesPerPoint = 160;

/// 위치 기록 영역. `location/data.json`(이동 점 · 머문 곳 이름 행)을 쓴다.
///
/// 데이터만 바꾼다 — 위치 기록 서비스(네이티브 `location_record`)는 켜지도 끄지도 않는다.
class LocationBackupArea implements BackupAreaSource {
  LocationBackupArea(this._db, this._recorder);

  final LocationDatabase _db;

  /// 복원 뒤 기록이 꺼져 있는지만 본다.
  final LocationRecorder _recorder;

  List<TableInfo<Table, dynamic>> get _tables => [
    _db.locationPoints,
    _db.placeNames,
  ];

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.location;

  @override
  Map<String, int> get schema => {'location': _db.schemaVersion};

  @override
  Future<Map<String, int>> counts() async => {
    'points': await countRows(_db, _db.locationPoints),
  };

  @override
  Future<int> estimatedBytes() async =>
      (await countRows(_db, _db.locationPoints) +
          await countRows(_db, _db.placeNames)) *
      _bytesPerPoint;

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    await out.create(recursive: true);
    final data = await dumpTables(_db, _tables);
    await writeAreaJson(out, _dataFile, data);
    return {'points': data[_db.locationPoints.actualTableName]!.length};
  }

  /// 테이블 사이에 참조가 없어 파일 모양만 본다.
  @override
  Future<void> validate(Directory root) => _readData(root);

  @override
  Future<void> replace(Directory root) async {
    final data = await _readData(root);
    await _db.transaction(() async {
      for (final t in _tables) {
        await deleteAllRows(_db, t);
        await insertRows(_db, t, data[t.actualTableName]!);
      }
    });
  }

  /// 서비스 상태는 지금 기기의 것 그대로 둔다 — 꺼져 있으면 켜는 것은 사용자 몫이라 알린다.
  /// 상태를 읽지 못하면 켜져 있다고 할 수 없으니 알린다.
  @override
  Future<Set<RestoreNotice>> afterRestore() async {
    final RecorderStatus status;
    try {
      status = await _recorder.status();
    } on Object {
      return const {RestoreNotice.locationRecordingOff};
    }
    return switch (status) {
      RecorderOff() => const {RestoreNotice.locationRecordingOff},
      RecorderRunning() || RecorderBlocked() => const {},
    };
  }

  Future<TableRows> _readData(Directory root) =>
      readTableRows(_areaDir(root), _dataFile, _tables);
}
