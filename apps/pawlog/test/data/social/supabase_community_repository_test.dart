import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/social/supabase_community_repository.dart';
import 'package:pawlog/data/social/walk_post_cursor.dart';
import 'package:pawlog/domain/social/entity/walk_post.dart';
import 'package:pawlog/domain/social/entity/walk_post_draft.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_community_gateway.dart';

Map<String, dynamic> _row(
  String id, {
  String createdAt = '2026-10-17T09:00:00.123456+00:00',
  String? avatar,
  Object? route,
}) => {
  'id': id,
  'author_id': 'a1',
  'local_walk_id': 'w-$id',
  'started_at': '2026-10-17T08:00:00+00:00',
  'duration_seconds': 1800,
  'distance_meters': 1234.5,
  'dog_names': ['콩이', '보리'],
  'memo': '공원',
  'route_preview': route,
  'created_at': createdAt,
  'author_nickname': '콩이네',
  'author_avatar_url': avatar,
  'like_count': 3,
  'liked_by_me': true,
};

FailureCode? _codeOf(Result<Object?> result) => switch (result) {
  Err(:final failure) => failure.failureCode,
  Ok() => null,
};

T _value<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw TestFailure('$failure'),
};

void main() {
  late FakeCommunityGateway gateway;
  late SupabaseCommunityRepository repository;

  setUp(() {
    gateway = FakeCommunityGateway();
    repository = SupabaseCommunityRepository(gateway);
  });

  group('fetchPage', () {
    test('행을 WalkPost 로 옮긴다 — UTC 를 현지 시각으로, 아바타 없음은 null', () async {
      gateway.rows = [
        _row(
          'p1',
          route: [
            {'lat': 37.5, 'lng': 127.1},
            {'lat': 37.6, 'lng': 127},
          ],
        ),
      ];

      final post = _value(await repository.fetchPage()).items.single;

      expect(
        post,
        WalkPost(
          id: 'p1',
          authorId: 'a1',
          authorNickname: '콩이네',
          localWalkId: 'w-p1',
          startedAt: DateTime.utc(2026, 10, 17, 8).toLocal(),
          duration: const Duration(minutes: 30),
          distanceMeters: 1234.5,
          dogNames: const ['콩이', '보리'],
          memo: '공원',
          routePreview: const [
            GeoPoint(lat: 37.5, lng: 127.1),
            GeoPoint(lat: 37.6, lng: 127),
          ],
          createdAt: DateTime.utc(2026, 10, 17, 9, 0, 0, 123, 456).toLocal(),
          likeCount: 3,
          likedByMe: true,
        ),
      );
      expect(post.authorAvatarUrl, isNull);
      expect(post.startedAt.isUtc, isFalse);
      expect(post.createdAt.isUtc, isFalse);
    });

    test('경로가 null 이거나 모양이 깨졌으면 빈 경로로 둔다 — 한 행 때문에 목록이 끊기지 않게', () async {
      gateway.rows = [
        _row('p1', avatar: 'https://x/a.png'),
        _row('p2', route: 'oops'),
        _row(
          'p3',
          route: [
            {'lat': 'x'},
          ],
        ),
      ];

      final items = _value(await repository.fetchPage()).items;

      expect(items.map((p) => p.routePreview), everyElement(isEmpty));
      expect(items.first.authorAvatarUrl, 'https://x/a.png');
    });

    test('limit + 1 개를 읽어 다음 페이지를 알고, 커서는 돌려준 마지막 글로 만든다', () async {
      gateway.rows = [
        _row('p1', createdAt: '2026-10-17T09:00:03+00:00'),
        _row('p2', createdAt: '2026-10-17T09:00:02.000001+00:00'),
        _row('p3', createdAt: '2026-10-17T09:00:01+00:00'),
      ];

      final page = _value(await repository.fetchPage(limit: 2));

      expect(gateway.fetchCalls.single.limit, 3);
      expect(gateway.fetchCalls.single.before, isNull);
      expect(page.items.map((p) => p.id), ['p1', 'p2']);
      expect(
        WalkPostCursor.decode(page.nextCursor),
        WalkPostCursor(
          createdAt: DateTime.utc(2026, 10, 17, 9, 0, 2, 0, 1),
          id: 'p2',
        ),
      );
    });

    test('마지막 페이지면 다음 커서가 없다', () async {
      gateway.rows = [_row('p1')];

      expect(_value(await repository.fetchPage(limit: 2)).nextCursor, isNull);
    });

    test('받은 커서를 풀어 게이트웨이에 넘긴다', () async {
      final cursor = WalkPostCursor(
        createdAt: DateTime.utc(2026, 10, 17, 9),
        id: 'p9',
      );

      await repository.fetchPage(after: cursor.encode());

      expect(gateway.fetchCalls.single.before, cursor);
    });

    test('깨진 커서는 feedCursorInvalid 이고 서버에 묻지 않는다', () async {
      final result = await repository.fetchPage(after: '!!!');

      expect(_codeOf(result), FailureCode.feedCursorInvalid);
      expect(gateway.fetchCalls, isEmpty);
    });

    test('서버 오류는 core 매퍼로 바꾼다', () async {
      gateway.fetchError = const PostgrestException(
        message: 'denied',
        code: '42501',
      );

      expect(
        _codeOf(await repository.fetchPage()),
        FailureCode.forbiddenOrDeleted,
      );
    });
  });

  group('publish', () {
    final draft = WalkPostDraft(
      localWalkId: 'w1',
      startedAt: DateTime.utc(2026, 10, 17, 8, 30),
      duration: const Duration(minutes: 30, seconds: 5),
      distanceMeters: 1200.5,
      dogNames: const ['콩이'],
      memo: '메모',
      routePreview: const [
        GeoPoint(lat: 37.5, lng: 127.1),
        GeoPoint(lat: 37.6, lng: 127),
      ],
    );

    test('RPC 인자로 옮기고 글 id 를 돌려준다', () async {
      final id = _value(await repository.publish(draft));

      expect(id, 'p1');
      expect(gateway.publishedParams.single, {
        'p_local_walk_id': 'w1',
        'p_started_at': '2026-10-17T08:30:00.000Z',
        'p_duration_seconds': 1805,
        'p_distance_meters': 1200.5,
        'p_dog_names': ['콩이'],
        'p_memo': '메모',
        'p_route_preview': [
          {'lat': 37.5, 'lng': 127.1},
          {'lat': 37.6, 'lng': 127.0},
        ],
      });
    });

    test('경로가 비면 route_preview 는 null 로 보낸다(경로 없이 공유)', () async {
      await repository.publish(
        draft.copyWith(routePreview: const [], memo: null),
      );

      expect(gateway.publishedParams.single['p_route_preview'], isNull);
      expect(gateway.publishedParams.single['p_memo'], isNull);
    });

    test('현지 시각도 UTC 로 보낸다', () async {
      final local = DateTime(2026, 10, 17, 17, 30);

      await repository.publish(draft.copyWith(startedAt: local));

      expect(
        gateway.publishedParams.single['p_started_at'],
        local.toUtc().toIso8601String(),
      );
    });

    test('서버 오류는 Err', () async {
      gateway.publishError = const PostgrestException(
        message: 'check',
        code: '23514',
      );

      expect(
        _codeOf(await repository.publish(draft)),
        FailureCode.constraintViolation,
      );
    });
  });

  group('unpublish', () {
    test('공유한 적 없는 산책(false)도 Ok', () async {
      gateway.unpublishResult = false;

      expect(await repository.unpublish('w1'), isA<Ok<void>>());
      expect(gateway.unpublished, ['w1']);
    });
  });

  group('isPublished', () {
    test('내 살아 있는 글이 있으면 true', () async {
      gateway.live.add(('u1', 'w1'));

      expect(_value(await repository.isPublished('w1')), isTrue);
      expect(_value(await repository.isPublished('w2')), isFalse);
    });

    test('남의 글은 세지 않는다', () async {
      gateway.live.add(('someone', 'w1'));

      expect(_value(await repository.isPublished('w1')), isFalse);
    });

    test('로그인하지 않았으면 false', () async {
      gateway
        ..currentUserId = null
        ..live.add(('u1', 'w1'));

      expect(_value(await repository.isPublished('w1')), isFalse);
    });
  });

  group('좋아요', () {
    test('like 는 post_id 만 넣는다', () async {
      expect(await repository.like('p1'), isA<Ok<void>>());
      expect(gateway.likes, ['p1']);
    });

    test('이미 누른 좋아요(409 · 23505)는 Ok', () async {
      gateway.likeError = const PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );

      expect(await repository.like('p1'), isA<Ok<void>>());
    });

    test('지운 글에 누르면(42501) forbiddenOrDeleted', () async {
      gateway.likeError = const PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );

      expect(
        _codeOf(await repository.like('p1')),
        FailureCode.forbiddenOrDeleted,
      );
    });

    test('unlike 는 내 행만 지운다 — 없는 좋아요도 Ok', () async {
      expect(await repository.unlike('p1'), isA<Ok<void>>());
      expect(gateway.unlikes.single, (postId: 'p1', userId: 'u1'));
    });

    test('로그인하지 않았으면 authenticationRequired', () async {
      gateway.currentUserId = null;

      expect(
        _codeOf(await repository.like('p1')),
        FailureCode.authenticationRequired,
      );
      expect(
        _codeOf(await repository.unlike('p1')),
        FailureCode.authenticationRequired,
      );
      expect(gateway.likes, isEmpty);
      expect(gateway.unlikes, isEmpty);
    });
  });
}
