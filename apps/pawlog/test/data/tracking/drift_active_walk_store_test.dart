import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/database/walk_database.dart';
import 'package:pawlog/data/tracking/drift_active_walk_store.dart';
import 'package:pawlog/domain/tracking/entity/tracking_notice.dart';
import 'package:pawlog/domain/tracking/entity/walk_session.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

import '../../support/fakes.dart';

void main() {
  late WalkDatabase db;
  late DriftActiveWalkStore store;

  const notice = TrackingNotice(title: '산책 중', text: '하늘 · 가을');
  final session = WalkSession(
    dogIds: const ['d1', 'd2'],
    startedAt: t0,
    points: const [],
    distanceMeters: 0,
  );

  WalkTrackPoint pointAt(int i, {double? accuracy}) => WalkTrackPoint(
    point: GeoPoint(lat: 37.5 + i * 0.001, lng: 127.0 + i * 0.001),
    recordedAt: t0.add(Duration(seconds: 10 * i)),
    accuracy: accuracy,
  );

  setUp(() {
    db = WalkDatabase(NativeDatabase.memory());
    store = DriftActiveWalkStore(db);
  });
  tearDown(() => db.close());

  test('비어 있으면 load 는 null 이다', () async {
    expect(await store.load(), isNull);
  });

  test('begin 뒤 load 는 같은 반려견 · 시작 시각 · 빈 점 · 거리 0 · 알림을 준다', () async {
    await store.begin(session, notice);

    final snapshot = (await store.load())!;
    expect(snapshot.session.dogIds, ['d1', 'd2']);
    expect(snapshot.session.startedAt, t0);
    expect(snapshot.session.endedAt, isNull);
    expect(snapshot.session.points, isEmpty);
    expect(snapshot.session.distanceMeters, 0);
    expect(snapshot.session.pausedDuration, Duration.zero);
    expect(snapshot.session.pausedAt, isNull);
    expect(snapshot.notice, notice);
  });

  test('appendPoint 는 seq 순으로 점과 누적 거리를 남긴다', () async {
    await store.begin(session, notice);
    await store.appendPoint(0, pointAt(0, accuracy: 5), 0);
    await store.appendPoint(1, pointAt(1), 10);
    await store.appendPoint(2, pointAt(2, accuracy: 8.5), 20);

    final loaded = (await store.load())!.session;
    expect(loaded.points, [
      pointAt(0, accuracy: 5),
      pointAt(1),
      pointAt(2, accuracy: 8.5),
    ]);
    expect(loaded.distanceMeters, 20);
  });

  test('updateTiming 은 멈춤 합 · 멈춘 시각 · 끝난 시각을 덮어쓴다', () async {
    await store.begin(session, notice);
    final pausedAt = t0.add(const Duration(minutes: 20));
    final endedAt = t0.add(const Duration(minutes: 30));

    await store.updateTiming(
      session.copyWith(
        pausedDuration: const Duration(minutes: 5),
        pausedAt: pausedAt,
        endedAt: endedAt,
      ),
    );

    final loaded = (await store.load())!.session;
    expect(loaded.pausedDuration, const Duration(minutes: 5));
    expect(loaded.pausedAt, pausedAt);
    expect(loaded.endedAt, endedAt);
  });

  test('두 번째 begin 은 이전 세션의 점까지 지운다', () async {
    await store.begin(session, notice);
    await store.appendPoint(0, pointAt(0), 0);
    await store.appendPoint(1, pointAt(1), 10);

    final next = session.copyWith(
      dogIds: const ['d3'],
      startedAt: t0.add(const Duration(hours: 1)),
    );
    const nextNotice = TrackingNotice(title: '다시', text: '바다');
    await store.begin(next, nextNotice);

    final snapshot = (await store.load())!;
    expect(snapshot.session.dogIds, ['d3']);
    expect(snapshot.session.startedAt, t0.add(const Duration(hours: 1)));
    expect(snapshot.session.points, isEmpty);
    expect(snapshot.session.distanceMeters, 0);
    expect(snapshot.notice, nextNotice);
  });

  test('clear 뒤 load 는 null 이다', () async {
    await store.begin(session, notice);
    await store.appendPoint(0, pointAt(0), 0);

    await store.clear();

    expect(await store.load(), isNull);
    expect(await db.select(db.activeWalkPoints).get(), isEmpty);
  });
}
