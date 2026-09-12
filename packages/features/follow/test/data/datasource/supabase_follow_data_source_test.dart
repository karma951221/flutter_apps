import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_follow/feature_follow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// 0행이 지워진 DELETE 를 흉내 내는 builder.
///
/// PostgREST 는 지운 행이 없어도 DELETE 자체는 성공으로 끝낸다. `.select()`
/// 를 붙였을 때만 "행 하나"를 요구하게 되고, 그때 [_SingleBuilder] 가 던지는
/// PGRST116 이 돌아온다.
class _DeleteBuilder extends Mock implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      _SelectBuilder();

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic) onValue, {
    Function? onError,
  }) => Future<dynamic>.value().then(onValue, onError: onError);
}

class _SelectBuilder extends Mock
    implements PostgrestTransformBuilder<PostgrestList> {
  @override
  PostgrestTransformBuilder<PostgrestMap> single() => _SingleBuilder();
}

/// 지울 행이 없을 때의 `.single()` — PostgREST 가 PGRST116 을 돌려준다.
class _SingleBuilder extends Mock
    implements PostgrestTransformBuilder<PostgrestMap> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap) onValue, {
    Function? onError,
  }) => Future<PostgrestMap>.error(
    PostgrestException(
      message: 'JSON object requested, multiple (or no) rows returned',
      code: 'PGRST116',
    ),
  ).then(onValue, onError: onError);
}

final _me = User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-08-30T09:00:00Z',
);

void main() {
  late _MockSupabaseClient client;
  late _MockQueryBuilder table;
  late _DeleteBuilder delete;

  setUp(() {
    client = _MockSupabaseClient();
    table = _MockQueryBuilder();
    delete = _DeleteBuilder();

    final auth = _MockGoTrueClient();
    when(() => auth.currentUser).thenReturn(_me);
    when(() => client.auth).thenReturn(auth);
    // builder 들은 Future 를 구현하므로 thenReturn 을 쓸 수 없다.
    when(() => client.from('follows')).thenAnswer((_) => table);
    when(table.delete).thenAnswer((_) => delete);
    when(() => delete.eq(any(), any())).thenAnswer((_) => delete);
  });

  test('지울 행이 없어도 팔로우 해제는 성공한다', () async {
    // 팔로우 행은 내가 지우지 않아도 사라질 수 있다 — 상대가 나를 차단하면
    // blocks_drop_follows 트리거가 지운다. 그때 해제가 notFound 로 실패하면
    // FollowActionCubit 이 버튼을 '팔로잉'으로 되돌려, 팔로우하지 않는데
    // 팔로잉으로 보이는 상태가 남는다. 해제는 멱등이어야 한다.
    await SupabaseFollowDataSource(client).unfollowUser('other');

    verify(() => delete.eq('followee_id', 'other')).called(1);
  });

  test('로그인하지 않았으면 해제를 시도하지 않는다', () async {
    final auth = _MockGoTrueClient();
    when(() => auth.currentUser).thenReturn(null);
    when(() => client.auth).thenReturn(auth);

    await expectLater(
      SupabaseFollowDataSource(client).unfollowUser('other'),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.from(any()));
  });
}
