import 'package:daylog/core/error/failure.dart';
import 'package:daylog/features/trade/data/datasource/supabase_trade_data_source.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late _MockSupabaseClient client;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    when(() => auth.currentUser).thenReturn(null);
    when(() => client.auth).thenReturn(auth);
  });

  // `SupabaseFollowDataSource` 의 테스트는 `.from()` 기반 메서드(`unfollowUser`)만
  // 다루고 RPC 호출은 별도로 흉내 내지 않는다. `place_trade_order` 등 나머지
  // RPC 메서드는 supabase-dart 의 `PostgrestFilterBuilder` 체인을 mocktail 로
  // 온전히 흉내 내야 해서 여기서는 로그인 여부에 따라 갈리는 분기(가장 값이
  // 큰 버그 지점)만 단위 테스트로 확인하고, RPC 응답 파싱·쿼리 형태 자체는
  // `supabase/tests/`의 실 서버 검증 스크립트에 맡긴다(보고서 참고).

  test('로그인하지 않았으면 판을 시작하지 않는다', () async {
    await expectLater(
      SupabaseTradeDataSource(client).startSession(),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test('로그인하지 않았으면 주문을 넣지 않는다', () async {
    await expectLater(
      SupabaseTradeDataSource(
        client,
      ).placeOrder(sessionId: 's1', side: TradeSide.buy, quantity: 1),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test('로그인하지 않았으면 진행하지 않는다', () async {
    await expectLater(
      SupabaseTradeDataSource(client).advance('s1'),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test('로그인하지 않았으면 끝내지 않는다', () async {
    await expectLater(
      SupabaseTradeDataSource(client).finish('s1'),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.rpc(any(), params: any(named: 'params')));
  });

  test('로그인하지 않았으면 진행 중인 판 id 를 조회하지 않는다', () async {
    await expectLater(
      SupabaseTradeDataSource(client).getActiveSessionId(),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.from(any()));
  });

  test('로그인하지 않았으면 지난 판 목록을 조회하지 않는다', () async {
    await expectLater(
      SupabaseTradeDataSource(client).getPastSessions(limit: 20),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => client.from(any()));
  });

  test('getSession 은 로그인 여부를 확인하지 않고 곧바로 RPC 를 부른다', () async {
    // 게스트도 끝난 판의 결과를 열 수 있어야 한다 — 로그인 검사를 걸지 않는
    // 유일한 메서드다. 여기서는 rpc 호출 자체가 일어나는지만 확인한다.
    when(
      () => client.rpc('get_trade_session', params: {'session_id': 's1'}),
    ).thenThrow(Exception('stub'));

    await expectLater(
      SupabaseTradeDataSource(client).getSession('s1'),
      throwsA(isA<Exception>()),
    );
    verify(
      () => client.rpc('get_trade_session', params: {'session_id': 's1'}),
    ).called(1);
  });
}
