import 'package:core/core.dart';
import 'package:daylog/features/post/data/datasource/supabase_post_data_source.dart';
import 'package:daylog/features/post/domain/entity/post_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockIdGenerator extends Mock implements IdGenerator {}

class _MockImageStorage extends Mock implements ImageStorage {}

final _me = User(
  id: 'me',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-09-08T09:00:00Z',
);

/// 요청이 실제로 나가는 자리에서 멈추게 하는 표식.
///
/// PostgREST 응답까지 흉내 내려면 `PostgrestFilterBuilder` 체인을 통째로
/// 가짜로 만들어야 한다. 여기서 값이 큰 것은 **어느 경로로 가는가**뿐이라
/// 호출 지점에서 던지고, 그 호출이 있었는지를 단언한다
/// (`supabase_trade_data_source_test.dart` 와 같은 방식).
class _Stop implements Exception {
  const _Stop();
}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late _MockIdGenerator ids;
  late _MockImageStorage images;

  SupabasePostDataSource dataSource() =>
      SupabasePostDataSource(client, ids, images);

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    ids = _MockIdGenerator();
    images = _MockImageStorage();
    when(() => auth.currentUser).thenReturn(_me);
    when(() => client.auth).thenReturn(auth);
    when(() => ids.newId()).thenReturn('folder-id');
    when(
      () => images.removePaths(
        bucket: any(named: 'bucket'),
        paths: any(named: 'paths'),
      ),
    ).thenAnswer((_) async {});
  });

  test('로그인하지 않았으면 작성하지 않는다', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(
      await dataSource().createPost(const PostDraft(content: '글')),
      isNull,
    );
    verifyNever(() => client.from(any()));
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test('판을 붙이면 이미지가 없어도 RPC 로 만든다', () async {
    // `trade_session_id` 에는 INSERT GRANT 가 없다(docs/schema.md §5). 이미지가
    // 없다고 직접 insert 로 새면 42501 로 실패한다.
    when(
      () => client.rpc<dynamic>(
        'create_post_with_images',
        params: any(named: 'params'),
      ),
    ).thenThrow(const _Stop());

    await expectLater(
      dataSource().createPost(
        const PostDraft(content: '판 공유', tradeSessionId: 'session-1'),
      ),
      throwsA(isA<_Stop>()),
    );

    final params =
        verify(
              () => client.rpc<dynamic>(
                'create_post_with_images',
                params: captureAny(named: 'params'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(params['content'], '판 공유');
    expect(params['images'], isEmpty);
    expect(params['trade_session_id'], 'session-1');
    verifyNever(() => client.from(any()));
  });

  test('판도 이미지도 없으면 기존대로 posts 에 직접 넣는다', () async {
    when(() => client.from('posts')).thenThrow(const _Stop());

    await expectLater(
      dataSource().createPost(const PostDraft(content: '글만')),
      throwsA(isA<_Stop>()),
    );

    verify(() => client.from('posts')).called(1);
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });
}
