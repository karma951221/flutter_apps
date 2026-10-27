import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/alarm/archive/drift_ring_archive.dart';
import 'package:walk/data/alarm/archive/ring_archive_database.dart';
import 'package:walk/domain/alarm/entity/archived_ring.dart';
import 'package:walk/domain/alarm/entity/ring_log_entry.dart';

void main() {
  late RingArchiveDatabase db;
  late DriftRingArchive archive;

  setUp(() {
    db = RingArchiveDatabase(NativeDatabase.memory());
    archive = DriftRingArchive(db);
  });
  tearDown(() => db.close());

  ArchivedRing ring(DateTime at, {String? label = '출근', int packageId = 300, RingLogKind kind = RingLogKind.stopped}) =>
      ArchivedRing(
        entry: RingLogEntry(at: at, packageId: packageId, kind: kind),
        label: label,
        hour: label == null ? null : 7,
        minute: label == null ? null : 0,
      );

  test('saveAll 뒤 read 는 기간 안의 것만 오래된 순으로 돌려준다', () async {
    final d1 = DateTime(2026, 10, 1, 7);
    final d2 = DateTime(2026, 10, 2, 7);
    final d3 = DateTime(2026, 10, 3, 7);
    await archive.saveAll([ring(d3), ring(d1), ring(d2)]);

    final all = await archive.read(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 4));
    expect(all.map((r) => r.entry.at), [d1, d2, d3]);

    final got = await archive.read(from: DateTime(2026, 10, 2), to: DateTime(2026, 10, 3));
    expect(got, hasLength(1));
    expect(got.single.entry.at, d2);
    expect(got.single.entry.packageId, 300);
    expect(got.single.entry.kind, RingLogKind.stopped);
    expect(got.single.label, '출근');
    expect(got.single.hour, 7);
    expect(got.single.minute, 0);
  });

  test('같은 (at, packageId, kind) 를 두 번 저장하면 하나만 남고 처음 라벨을 유지한다', () async {
    final at = DateTime(2026, 10, 2, 7);
    await archive.saveAll([ring(at, label: '출근')]);
    await archive.saveAll([ring(at, label: '바뀜')]);

    final got = await archive.read(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 3));
    expect(got, hasLength(1));
    expect(got.single.label, '출근');
  });

  test('지운 알람(라벨 null)도 저장된다', () async {
    final at = DateTime(2026, 10, 2, 7);
    await archive.saveAll([ring(at, label: null)]);

    final got = await archive.read(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 3));
    expect(got, hasLength(1));
    expect(got.single.label, isNull);
    expect(got.single.hour, isNull);
    expect(got.single.minute, isNull);
  });
}
