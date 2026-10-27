import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/alarm/entity/archived_ring.dart';
import '../../../domain/alarm/entity/ring_log_entry.dart';
import '../../../domain/alarm/ring_log/ring_archive.dart';
import 'ring_archive_database.dart';

@LazySingleton(as: RingArchive)
class DriftRingArchive implements RingArchive {
  DriftRingArchive(this._db);

  final RingArchiveDatabase _db;

  @override
  Future<void> saveAll(List<ArchivedRing> rings) => _db.batch((b) {
    b.insertAll(
      _db.archivedRings,
      [
        for (final r in rings)
          ArchivedRingsCompanion.insert(
            at: r.entry.at,
            packageId: r.entry.packageId,
            kind: r.entry.kind,
            label: Value(r.label),
            hour: Value(r.hour),
            minute: Value(r.minute),
          ),
      ],
      mode: InsertMode.insertOrIgnore,
    );
  });

  @override
  Future<List<ArchivedRing>> read({required DateTime from, required DateTime to}) async {
    final query = _db.select(_db.archivedRings)
      ..where((t) => t.at.isBiggerOrEqualValue(from) & t.at.isSmallerOrEqualValue(to))
      ..orderBy([(t) => OrderingTerm.asc(t.at)]);
    return [
      for (final row in await query.get())
        ArchivedRing(
          entry: RingLogEntry(at: row.at, packageId: row.packageId, kind: row.kind),
          label: row.label,
          hour: row.hour,
          minute: row.minute,
        ),
    ];
  }
}
