import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../domain/backup/backup_failure.dart';
import 'drift_rows.dart';

/// 행 목록을 테이블 이름별로 묶은 것. `data.json` 같은 영역 파일의 모양이다.
typedef TableRows = Map<String, List<Map<String, Object?>>>;

/// `dir/name` 에 [json] 을 쓴다.
Future<void> writeAreaJson(Directory dir, String name, Object? json) =>
    File('${dir.path}/$name').writeAsString(jsonEncode(json));

/// `dir/name` 의 JSON 객체를 읽는다. 없거나 깨졌거나 객체가 아니면 integrity.
/// [optional] 이면 없는 파일을 빈 객체로 본다.
Future<Map<String, Object?>> readAreaJson(
  Directory dir,
  String name, {
  bool optional = false,
}) async {
  final file = File('${dir.path}/$name');
  if (optional && !await file.exists()) return const {};
  try {
    return jsonDecode(await file.readAsString()) as Map<String, Object?>;
  } catch (_) {
    throw const BackupException(BackupFailure.integrity);
  }
}

/// [tables] 의 모든 행을 한 트랜잭션에서 읽어 테이블 이름별로 돌려준다.
Future<TableRows> dumpTables(
  GeneratedDatabase db,
  Iterable<TableInfo<Table, dynamic>> tables,
) => db.transaction(
  () async => {
    for (final t in tables) t.actualTableName: await dumpTable(db, t),
  },
);

/// `dir/name` 을 [tables] 의 이름 → 행 목록으로 읽는다. 파일이 없거나 테이블이 빠졌거나
/// 행 모양이 다르면 integrity.
Future<TableRows> readTableRows(
  Directory dir,
  String name,
  Iterable<TableInfo<Table, dynamic>> tables,
) async {
  final json = await readAreaJson(dir, name);
  try {
    return {
      for (final t in tables)
        t.actualTableName: [
          for (final row in json[t.actualTableName]! as List<Object?>)
            row! as Map<String, Object?>,
        ],
    };
  } catch (_) {
    throw const BackupException(BackupFailure.integrity);
  }
}

/// [table] 의 행 수.
Future<int> countRows(
  GeneratedDatabase db,
  TableInfo<Table, dynamic> table,
) async {
  final row = await db
      .customSelect(
        'SELECT COUNT(*) AS c FROM "${table.actualTableName}"',
        readsFrom: {table},
      )
      .getSingle();
  return row.read<int>('c');
}
