@Tags(['integration'])
library;

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/core/config/app_config.dart';
import 'package:pawlog/data/social/supabase_auth_gateway.dart';
import 'package:pawlog/data/social/supabase_auth_repository.dart';
import 'package:pawlog/data/social/supabase_community_gateway.dart';
import 'package:pawlog/data/social/supabase_community_repository.dart';
import 'package:pawlog/domain/social/entity/walk_post.dart';
import 'package:pawlog/domain/social/entity/walk_post_draft.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 로컬 Supabase(`supabase start`, 마이그레이션 적용)에 실제로 공유 · 좋아요를 해 본다.
/// 기본 `flutter test` 는 건너뛴다(dart_test.yaml). 실행:
/// `flutter test --run-skipped -t integration test/data/social/supabase_community_integration_test.dart`.
///
/// `testWidgets` 바인딩은 HTTP 를 막으므로 plain `test` 만 쓴다.
void main() {
  late SupabaseClient client;
  late SupabaseAuthRepository auth;
  late SupabaseCommunityRepository repository;
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  T value<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw TestFailure('$failure'),
  };

  Future<WalkPost?> findInFirstPage(String id) async {
    final page = value(await repository.fetchPage(limit: 50));
    return page.items.where((p) => p.id == id).firstOrNull;
  }

  setUp(() async {
    client = SupabaseClient(
      'http://127.0.0.1:54321',
      AppConfig.localPublishableKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );
    auth = SupabaseAuthRepository(SupabaseClientAuthGateway(client));
    repository = SupabaseCommunityRepository(
      SupabaseClientCommunityGateway(client),
    );
  });
  tearDown(() => client.dispose());

  test('공유 → 목록에 보임 → 좋아요 → 공유 취소 → 사라짐', () async {
    value(
      await auth.signUp(
        'pawlog_c_$stamp@example.com',
        'password123',
        'pc$stamp',
      ),
    );
    // uuid 형식의 기기 산책 id.
    final hex = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(12, '0');
    final localWalkId =
        '00000000-0000-4000-8000-${hex.substring(hex.length - 12)}';
    final draft = WalkPostDraft(
      localWalkId: localWalkId,
      startedAt: DateTime(2026, 10, 17, 8, 30),
      duration: const Duration(minutes: 30),
      distanceMeters: 1234.5,
      dogNames: const ['콩이', '보리'],
      memo: '공원 한 바퀴',
      routePreview: const [
        GeoPoint(lat: 37.5, lng: 127.1),
        GeoPoint(lat: 37.6, lng: 127),
      ],
    );

    final postId = value(await repository.publish(draft));
    expect(value(await repository.isPublished(localWalkId)), isTrue);

    final shared = await findInFirstPage(postId);
    expect(shared, isNotNull);
    expect(shared!.authorNickname, 'pc$stamp');
    expect(shared.startedAt, draft.startedAt);
    expect(shared.dogNames, draft.dogNames);
    expect(shared.routePreview, draft.routePreview);
    expect(shared.likeCount, 0);
    expect(shared.likedByMe, isFalse);

    value(await repository.like(postId));
    // 두 번 눌러도(409) Ok.
    value(await repository.like(postId));
    final liked = await findInFirstPage(postId);
    expect(liked!.likeCount, 1);
    expect(liked.likedByMe, isTrue);

    value(await repository.unlike(postId));
    // 없는 좋아요 지우기도 Ok.
    value(await repository.unlike(postId));
    expect((await findInFirstPage(postId))!.likeCount, 0);

    value(await repository.unpublish(localWalkId));
    // 공유하지 않은 산책 공유 취소도 Ok.
    value(await repository.unpublish(localWalkId));
    expect(value(await repository.isPublished(localWalkId)), isFalse);
    expect(await findInFirstPage(postId), isNull);
  });

  test('커서로 다음 페이지를 읽으면 겹치지 않고 이어진다', () async {
    value(
      await auth.signUp(
        'pawlog_k_$stamp@example.com',
        'password123',
        'pk$stamp',
      ),
    );
    final ids = <String>[];
    for (final suffix in ['000000000001', '000000000002']) {
      final draft = WalkPostDraft(
        localWalkId: '00000000-0000-4000-9000-$suffix',
        startedAt: DateTime(2026, 10, 17),
        duration: Duration.zero,
        distanceMeters: 0,
        dogNames: const ['콩이'],
        routePreview: const [],
      );
      ids.add(value(await repository.publish(draft)));
    }

    // 방금 올린 두 글이 맨 위다 — 다시 공유한 글은 created_at 이 now() 로 바뀐다.
    final first = value(await repository.fetchPage(limit: 1));
    final second = value(
      await repository.fetchPage(after: first.nextCursor, limit: 1),
    );

    expect(first.items.single.id, ids[1]);
    expect(first.items.single.routePreview, isEmpty);
    expect(second.items.single.id, ids[0]);

    for (final suffix in ['000000000001', '000000000002']) {
      value(await repository.unpublish('00000000-0000-4000-9000-$suffix'));
    }
  });

  test('공유한 산책을 고치면 새 메모가 보이고 목록 위치는 그대로다', () async {
    value(
      await auth.signUp(
        'pawlog_u_$stamp@example.com',
        'password123',
        'pu$stamp',
      ),
    );
    WalkPostDraft draftOf(String suffix, {String? memo}) => WalkPostDraft(
      localWalkId: '00000000-0000-4000-a000-$suffix',
      startedAt: DateTime(2026, 10, 18),
      duration: const Duration(minutes: 20),
      distanceMeters: 900,
      dogNames: const ['콩이'],
      memo: memo,
      routePreview: const [],
    );
    final older = value(
      await repository.publish(draftOf('000000000001', memo: '처음 메모')),
    );
    final newer = value(await repository.publish(draftOf('000000000002')));

    final updated = value(
      await repository.updatePublished(draftOf('000000000001', memo: '고친 메모')),
    );

    expect(updated, isTrue);
    final page = value(await repository.fetchPage(limit: 2));
    expect([for (final p in page.items) p.id], [newer, older]);
    expect(page.items.last.memo, '고친 메모');

    for (final suffix in ['000000000001', '000000000002']) {
      value(await repository.unpublish('00000000-0000-4000-a000-$suffix'));
    }
    // 공유 취소한 글은 고쳐도 되살아나지 않는다.
    expect(
      value(await repository.updatePublished(draftOf('000000000001'))),
      isFalse,
    );
    expect(await findInFirstPage(older), isNull);
  });
}
