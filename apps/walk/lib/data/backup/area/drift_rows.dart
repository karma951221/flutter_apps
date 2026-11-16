import 'package:drift/drift.dart';

/// [table] 의 모든 행을 컬럼 이름 그대로의 맵으로 읽는다. 날짜는 DB 에 저장된
/// 값(`storeDateTimeAsText` 면 문자열) 그대로라 JSON 으로 옮겨도 바뀌지 않는다.
Future<List<Map<String, Object?>>> dumpTable(
  GeneratedDatabase db,
  TableInfo<Table, dynamic> table,
) async {
  final rows = await db
      .customSelect(
        'SELECT * FROM "${table.actualTableName}" ORDER BY rowid',
        readsFrom: {table},
      )
      .get();
  return [for (final r in rows) r.data];
}

/// [rows] 를 [table] 에 넣는다. 컬럼 이름은 행의 키가 아니라 테이블 정의에서 가져오므로
/// 파일에서 온 키가 SQL 에 섞이지 않는다. 행에 없는 컬럼은 null 이다.
Future<void> insertRows(
  GeneratedDatabase db,
  TableInfo<Table, dynamic> table,
  List<Map<String, Object?>> rows,
) async {
  if (rows.isEmpty) return;
  final columns = [for (final c in table.$columns) c.name];
  final sql =
      'INSERT INTO "${table.actualTableName}" '
      '(${columns.map((c) => '"$c"').join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')})';
  for (final row in rows) {
    await db.customInsert(
      sql,
      variables: [for (final c in columns) Variable<Object>(row[c])],
      updates: {table},
    );
  }
}

/// [table] 의 모든 행을 지운다.
Future<void> deleteAllRows(
  GeneratedDatabase db,
  TableInfo<Table, dynamic> table,
) => db.customUpdate(
  'DELETE FROM "${table.actualTableName}"',
  updates: {table},
  updateKind: UpdateKind.delete,
);
