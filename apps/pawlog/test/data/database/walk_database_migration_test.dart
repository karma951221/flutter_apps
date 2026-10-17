import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/database/walk_database.dart';
import 'package:pawlog/data/tracking/drift_active_walk_store.dart';
import 'package:pawlog/data/walk/drift_walk_repository.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/domain/tracking/entity/tracking_notice.dart';
import 'package:pawlog/domain/tracking/entity/walk_session.dart';

import '../../support/fakes.dart';

/// v1 `WalkDatabase` 를 한 번 열어 `sqlite_master.sql` 로 뽑은 그대로다. 고치지 않는다.
const _v1Schema = [
  'CREATE TABLE "dogs" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "breed" TEXT NULL, "birthday" TEXT NULL, "photo_path" TEXT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "walks" ("id" TEXT NOT NULL, "started_at" TEXT NOT NULL, "ended_at" TEXT NOT NULL, "duration_seconds" INTEGER NOT NULL, "distance_meters" REAL NOT NULL, "memo" TEXT NULL, "route_preview" TEXT NULL, "created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "walk_dogs" ("walk_id" TEXT NOT NULL REFERENCES walks (id) ON DELETE CASCADE, "dog_id" TEXT NOT NULL REFERENCES dogs (id) ON DELETE CASCADE, PRIMARY KEY ("walk_id", "dog_id"))',
  'CREATE TABLE "walk_points" ("walk_id" TEXT NOT NULL REFERENCES walks (id) ON DELETE CASCADE, "seq" INTEGER NOT NULL, "lat" REAL NOT NULL, "lng" REAL NOT NULL, "recorded_at" TEXT NOT NULL, "accuracy" REAL NULL, PRIMARY KEY ("walk_id", "seq"))',
  'CREATE TABLE "walk_photos" ("id" TEXT NOT NULL, "walk_id" TEXT NOT NULL REFERENCES walks (id) ON DELETE CASCADE, "path" TEXT NOT NULL, "position" INTEGER NOT NULL, "created_at" TEXT NOT NULL, PRIMARY KEY ("id"))',
  'CREATE INDEX walks_started_at ON walks (started_at)',
  'CREATE INDEX walk_photos_walk_id ON walk_photos (walk_id)',
];

/// v2 `WalkDatabase` 를 한 번 열어 `sqlite_master.sql` 로 뽑은 그대로다(v1 + 진행 중 산책 두 테이블). 고치지 않는다.
const _v2Schema = [
  ..._v1Schema,
  'CREATE TABLE "active_walks" ("id" INTEGER NOT NULL, "dog_ids" TEXT NOT NULL, "started_at" TEXT NOT NULL, "ended_at" TEXT NULL, "paused_ms" INTEGER NOT NULL, "paused_at" TEXT NULL, "distance_meters" REAL NOT NULL, "notice_title" TEXT NOT NULL, "notice_text" TEXT NOT NULL, PRIMARY KEY ("id"))',
  'CREATE TABLE "active_walk_points" ("seq" INTEGER NOT NULL, "lat" REAL NOT NULL, "lng" REAL NOT NULL, "recorded_at" TEXT NOT NULL, "accuracy" REAL NULL, PRIMARY KEY ("seq"))',
];

const _v1Rows = [
  "INSERT INTO dogs (id, name, created_at, updated_at) "
      "VALUES ('d1', '하늘', '2026-10-03T09:00:00.000', '2026-10-03T09:00:00.000')",
  "INSERT INTO walks (id, started_at, ended_at, duration_seconds, distance_meters, created_at, updated_at) "
      "VALUES ('w1', '2026-10-03T09:00:00.000', '2026-10-03T09:30:00.000', 1800, 1200.5, "
      "'2026-10-03T09:30:00.000', '2026-10-03T09:30:00.000')",
];

WalkDatabase _open(List<String> statements, int userVersion) => WalkDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      for (final sql in statements) {
        raw.execute(sql);
      }
      raw.execute('PRAGMA user_version = $userVersion');
    },
  ),
);

Future<int> _userVersion(WalkDatabase db) async =>
    (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
      'user_version',
    );

void main() {
  group('v1 DB', () {
    late WalkDatabase db;

    setUp(() => db = _open([..._v1Schema, ..._v1Rows], 1));
    tearDown(() => db.close());

    test('최신으로 열면 기존 행이 그대로 남는다', () async {
      final dogs = await db.select(db.dogs).get();
      final walks = await db.select(db.walks).get();

      expect(dogs.map((d) => d.name), ['하늘']);
      expect(walks.map((w) => (w.id, w.durationSeconds, w.distanceMeters)), [
        ('w1', 1800, 1200.5),
      ]);
      expect(walks.single.isFavorite, isFalse);
    });

    test('최신으로 열면 진행 중 산책 테이블이 생긴다', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('active_walks', 'active_walk_points')",
          )
          .get();

      expect(rows.map((r) => r.read<String>('name')).toSet(), {
        'active_walks',
        'active_walk_points',
      });
      expect(await _userVersion(db), 3);
    });

    test('업그레이드한 DB 에서 복구 저장소가 동작한다', () async {
      final store = DriftActiveWalkStore(db);
      await store.begin(
        WalkSession(
          dogIds: const ['d1'],
          startedAt: t0,
          points: const [],
          distanceMeters: 0,
        ),
        const TrackingNotice(title: '산책 중', text: '하늘'),
      );

      expect((await store.load())!.session.dogIds, ['d1']);
    });
  });

  group('v2 DB', () {
    late WalkDatabase db;

    setUp(() => db = _open([..._v2Schema, ..._v1Rows], 2));
    tearDown(() => db.close());

    test('v3 로 열면 기존 산책은 즐겨찾기가 아니다', () async {
      final repository = DriftWalkRepository(db);

      final walk = ((await repository.findById('w1')) as Ok<Walk?>).value!;

      expect(walk.isFavorite, isFalse);
      expect(walk.distanceMeters, 1200.5);
      expect(await _userVersion(db), 3);
    });

    test('업그레이드한 DB 에서 즐겨찾기를 바꿀 수 있다', () async {
      final repository = DriftWalkRepository(db);

      final result = await repository.setFavorite('w1', true);

      expect(result, isA<Ok<void>>());
      final walk = ((await repository.findById('w1')) as Ok<Walk?>).value!;
      expect(walk.isFavorite, isTrue);
    });
  });
}
