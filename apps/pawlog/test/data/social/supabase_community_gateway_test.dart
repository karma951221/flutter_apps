import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/data/social/supabase_community_gateway.dart';
import 'package:pawlog/data/social/walk_post_cursor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockClient extends Mock implements SupabaseClient {}

class _MockAuth extends Mock implements GoTrueClient {}

class _MockQuery extends Mock implements SupabaseQueryBuilder {}

/// await 하면 [value] 를 내고, 걸린 필터 · 정렬 · 개수를 [calls] 에 적는 빌더.
class _FakeBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeBuilder(this.value);

  final T value;
  final calls = <String>[];

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    calls.add('eq $column $value');
    return this;
  }

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) {
    calls.add('or $filters');
    return this;
  }

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    calls.add('order $column ${ascending ? 'asc' : 'desc'}');
    return this;
  }

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) {
    calls.add('limit $count');
    return this;
  }

  @override
  PostgrestFilterBuilder<T> retry({
    bool enabled = true,
    int? count,
    Duration? requestTimeout,
  }) {
    calls.add('retry $enabled');
    return this;
  }

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) => Future.value(value).then(onValue, onError: onError);
}

void main() {
  late _MockClient client;
  late _MockAuth auth;
  late _MockQuery query;
  late SupabaseClientCommunityGateway gateway;

  setUp(() {
    client = _MockClient();
    auth = _MockAuth();
    query = _MockQuery();
    when(() => client.auth).thenReturn(auth);
    gateway = SupabaseClientCommunityGateway(client);
  });

  test('publish 는 publish_walk_post RPC 에 인자를 넘기고 글 id 를 돌려준다', () async {
    final params = {'p_local_walk_id': 'w1'};
    when(
      () => client.rpc<dynamic>('publish_walk_post', params: params),
    ).thenAnswer((_) => _FakeBuilder<dynamic>('p1'));

    expect(await gateway.publish(params), 'p1');
  });

  test('unpublish 는 unpublish_walk_post 의 boolean 을 돌려준다', () async {
    when(
      () => client.rpc<dynamic>(
        'unpublish_walk_post',
        params: {'p_local_walk_id': 'w1'},
      ),
    ).thenAnswer((_) => _FakeBuilder<dynamic>(false));

    expect(await gateway.unpublish('w1'), isFalse);
  });

  test('fetchPosts 는 보기를 (created_at desc, id desc) 로 읽고 커서 뒤만 거른다', () async {
    final builder = _FakeBuilder<PostgrestList>([
      {'id': 'p1'},
    ]);
    when(() => client.from('walk_posts_with_author')).thenAnswer((_) => query);
    when(() => query.select()).thenAnswer((_) => builder);

    final rows = await gateway.fetchPosts(
      limit: 21,
      before: WalkPostCursor(
        createdAt: DateTime.utc(2026, 10, 17, 9, 0, 0, 0, 5),
        id: 'p9',
      ),
    );

    expect(rows, [
      {'id': 'p1'},
    ]);
    expect(builder.calls, [
      'or created_at.lt.2026-10-17T09:00:00.000005Z,'
          'and(created_at.eq.2026-10-17T09:00:00.000005Z,id.lt.p9)',
      'order created_at desc',
      'order id desc',
      'limit 21',
      'retry false',
    ]);
  });

  test('첫 페이지는 커서 필터가 없다', () async {
    final builder = _FakeBuilder<PostgrestList>([]);
    when(() => client.from('walk_posts_with_author')).thenAnswer((_) => query);
    when(() => query.select()).thenAnswer((_) => builder);

    await gateway.fetchPosts(limit: 21);

    expect(builder.calls, [
      'order created_at desc',
      'order id desc',
      'limit 21',
      'retry false',
    ]);
  });

  test('hasLivePost 는 보기에서 내 글을 찾는다(보기는 공유 취소된 글을 가린다)', () async {
    final builder = _FakeBuilder<PostgrestList>([
      {'id': 'p1'},
    ]);
    when(() => client.from('walk_posts_with_author')).thenAnswer((_) => query);
    when(() => query.select('id')).thenAnswer((_) => builder);

    final found = await gateway.hasLivePost(authorId: 'u1', localWalkId: 'w1');

    expect(found, isTrue);
    expect(builder.calls, [
      'eq author_id u1',
      'eq local_walk_id w1',
      'limit 1',
      'retry false',
    ]);
  });

  test('insertLike 는 post_id 만 넣는다', () async {
    final builder = _FakeBuilder<dynamic>(null);
    when(() => client.from('walk_post_likes')).thenAnswer((_) => query);
    when(() => query.insert({'post_id': 'p1'})).thenAnswer((_) => builder);

    await gateway.insertLike('p1');

    verify(() => query.insert({'post_id': 'p1'})).called(1);
  });

  test('deleteLike 는 글 · 사용자로 한 행만 지운다', () async {
    final builder = _FakeBuilder<dynamic>(null);
    when(() => client.from('walk_post_likes')).thenAnswer((_) => query);
    when(() => query.delete()).thenAnswer((_) => builder);

    await gateway.deleteLike(postId: 'p1', userId: 'u1');

    expect(builder.calls, ['eq post_id p1', 'eq user_id u1']);
  });

  test('currentUserId 는 GoTrue 의 현재 사용자다', () {
    when(() => auth.currentUser).thenReturn(
      const User(
        id: 'u3',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-17T00:00:00Z',
      ),
    );

    expect(gateway.currentUserId, 'u3');
  });
}
