import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../domain/tracking/entity/active_walk_snapshot.dart';
import '../../domain/tracking/entity/tracking_notice.dart';
import '../../domain/tracking/entity/walk_session.dart';
import '../../domain/tracking/repository/active_walk_store.dart';
import '../../domain/walk/entity/geo_point.dart';
import '../../domain/walk/entity/walk_track_point.dart';
import '../database/walk_database.dart';

@LazySingleton(as: ActiveWalkStore)
class DriftActiveWalkStore implements ActiveWalkStore {
  DriftActiveWalkStore(this._db);

  /// 진행 중 산책은 언제나 한 건이라 머리 행 id 를 고정한다.
  static const _rowId = 1;

  final WalkDatabase _db;

  @override
  Future<ActiveWalkSnapshot?> load() async {
    final row = await (_db.select(
      _db.activeWalks,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return null;
    final points = await (_db.select(
      _db.activeWalkPoints,
    )..orderBy([(t) => OrderingTerm.asc(t.seq)])).get();
    return ActiveWalkSnapshot(
      session: WalkSession(
        dogIds: (jsonDecode(row.dogIds) as List<dynamic>).cast<String>(),
        startedAt: row.startedAt,
        endedAt: row.endedAt,
        points: [
          for (final p in points)
            WalkTrackPoint(
              point: GeoPoint(lat: p.lat, lng: p.lng),
              recordedAt: p.recordedAt,
              accuracy: p.accuracy,
            ),
        ],
        distanceMeters: row.distanceMeters,
        pausedDuration: Duration(milliseconds: row.pausedMs),
        pausedAt: row.pausedAt,
      ),
      notice: TrackingNotice(title: row.noticeTitle, text: row.noticeText),
    );
  }

  @override
  Future<void> begin(WalkSession session, TrackingNotice notice) =>
      _db.transaction(() async {
        await _db.delete(_db.activeWalkPoints).go();
        await _db.delete(_db.activeWalks).go();
        await _db
            .into(_db.activeWalks)
            .insert(
              ActiveWalksCompanion.insert(
                id: const Value(_rowId),
                dogIds: jsonEncode(session.dogIds),
                startedAt: session.startedAt,
                endedAt: Value(session.endedAt),
                pausedMs: session.pausedDuration.inMilliseconds,
                pausedAt: Value(session.pausedAt),
                distanceMeters: session.distanceMeters,
                noticeTitle: notice.title,
                noticeText: notice.text,
              ),
            );
      });

  @override
  Future<void> appendPoint(
    int seq,
    WalkTrackPoint point,
    double distanceMeters,
  ) => _db.transaction(() async {
    await _db
        .into(_db.activeWalkPoints)
        .insert(
          ActiveWalkPointsCompanion.insert(
            seq: Value(seq),
            lat: point.point.lat,
            lng: point.point.lng,
            recordedAt: point.recordedAt,
            accuracy: Value(point.accuracy),
          ),
        );
    await (_db.update(_db.activeWalks)..where((t) => t.id.equals(_rowId)))
        .write(ActiveWalksCompanion(distanceMeters: Value(distanceMeters)));
  });

  @override
  Future<void> updateTiming(WalkSession session) =>
      (_db.update(_db.activeWalks)..where((t) => t.id.equals(_rowId))).write(
        ActiveWalksCompanion(
          pausedMs: Value(session.pausedDuration.inMilliseconds),
          pausedAt: Value(session.pausedAt),
          endedAt: Value(session.endedAt),
        ),
      );

  @override
  Future<void> clear() => _db.transaction(() async {
    await _db.delete(_db.activeWalkPoints).go();
    await _db.delete(_db.activeWalks).go();
  });
}
