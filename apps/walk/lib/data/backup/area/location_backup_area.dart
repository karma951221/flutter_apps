import 'dart:io';

import 'package:drift/drift.dart';

import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
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
  LocationBackupArea(this._db);

  final LocationDatabase _db;

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

  /// 서비스 상태는 지금 기기의 것 그대로 둔다.
  @override
  Future<void> afterRestore() async {}

  Future<TableRows> _readData(Directory root) =>
      readTableRows(_areaDir(root), _dataFile, _tables);
}
