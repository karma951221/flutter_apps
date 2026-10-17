import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pawlog/core/supabase/supabase_initializer.dart';
import 'package:pawlog/core/supabase/timeout_http_client.dart';
import 'package:pawlog/data/social/supabase_auth_gateway.dart';
import 'package:pawlog/data/social/supabase_community_gateway.dart';
import 'package:pawlog/data/social/supabase_community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 서버가 멈춘 것처럼 어떤 요청에도 답하지 않는 http 클라이언트. 보낸 요청을 적는다.
class _HangingClient extends http.BaseClient {
  final requests = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add('${request.method} ${request.url.path}');
    return Completer<http.StreamedResponse>().future;
  }
}

/// 진짜 [SupabaseClient] — 재시도 · 세션 갱신은 SDK 그대로, 요청만 멈춘다.
SupabaseClient _client(_HangingClient hang, Duration timeout) => SupabaseClient(
  'http://127.0.0.1:54321',
  'anon',
  httpClient: TimeoutHttpClient(hang, timeout),
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

/// 곧 만료되는(만료 여유 30초 안) 로그인 세션 — 요청 전에 SDK 가 토큰 갱신부터 한다.
String _expiringSession() {
  final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 20;
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'exp': exp, 'sub': 'u1'})))
      .replaceAll('=', '');
  return jsonEncode({
    'access_token': 'eyJhbGciOiJIUzI1NiJ9.$payload.sig',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': exp,
    'refresh_token': 'r1',
    'user': {
      'id': 'u1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-10-01T00:00:00Z',
    },
  });
}

/// 짧은 시간 제한으로 [call] 을 실패시키고 걸린 시간을 돌려준다.
Future<Duration> _failTime(Future<Object?> Function() call) async {
  final watch = Stopwatch()..start();
  await expectLater(call(), throwsA(isA<TimeoutException>()));
  return watch.elapsed;
}

void main() {
  // postgrest 는 실패한 GET 을 기본 3번(1·2·4초 대기) 다시 보낸다. `SupabaseClient.from` 은
  // `PostgrestClientOptions` 의 재시도 설정을 넘기지 않아(supabase 2.16.1) 클라이언트 설정으로는
  // 끌 수 없다. 사용자가 기다리는 읽기는 요청마다 다시 시도하지 않는다.
  group('멈춘 서버 — 읽기는 다시 시도하지 않는다', () {
    const timeout = Duration(milliseconds: 100);
    late _HangingClient hang;
    late SupabaseClient client;

    setUp(() {
      hang = _HangingClient();
      client = _client(hang, timeout);
    });

    tearDown(() => client.dispose());

    test('모두의 산책 fetchPosts', () async {
      final gateway = SupabaseClientCommunityGateway(client);

      final elapsed = await _failTime(() => gateway.fetchPosts(limit: 21));

      expect(hang.requests, ['GET /rest/v1/walk_posts_with_author']);
      expect(elapsed, lessThan(const Duration(milliseconds: 900)));
    });

    test('공유 여부 hasLivePost', () async {
      final gateway = SupabaseClientCommunityGateway(client);

      await _failTime(
        () => gateway.hasLivePost(authorId: 'u1', localWalkId: 'w1'),
      );

      expect(hang.requests, hasLength(1));
    });

    test('프로필 fetchNickname · 닉네임 확인 isNicknameTaken', () async {
      final gateway = SupabaseClientAuthGateway(client);

      await _failTime(() => gateway.fetchNickname('u1'));
      await _failTime(() => gateway.isNicknameTaken('콩이네'));

      expect(hang.requests, hasLength(2));
    });
  });

  test('로그인 세션 갱신까지 멈춰도 첫 페이지는 12초 안에 네트워크 실패다', () {
    fakeAsync((async) {
      final hang = _HangingClient();
      final client = _client(hang, socialRequestTimeout);
      unawaited(client.auth.setInitialSession(_expiringSession()));
      async.flushMicrotasks();
      final repository = SupabaseCommunityRepository(
        SupabaseClientCommunityGateway(client),
      );

      Result<Object?>? result;
      unawaited(repository.fetchPage().then((r) => result = r));

      async.elapse(socialCallDeadline);

      expect(hang.requests.first, 'POST /auth/v1/token');
      expect(switch (result) {
        Err(:final failure) => failure.failureCode,
        _ => null,
      }, FailureCode.networkUnavailable);
      async.elapse(const Duration(minutes: 1));
    });
  });
}
