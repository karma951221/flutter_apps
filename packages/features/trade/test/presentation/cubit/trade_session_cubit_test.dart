import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_trade/feature_trade.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeUseCase extends Mock implements TradeUseCase {}

TradeSession _session({
  int step = 3,
  double cash = TradeRules.initialCash,
  double quantity = 0,
  bool isFinished = false,
  TradeResult? result,
}) => TradeSession(
  id: 'session-1',
  userId: 'user-1',
  step: step,
  cash: cash,
  quantity: quantity,
  isFinished: isFinished,
  candles: [
    for (var i = 0; i < TradeRules.totalCandles; i++)
      TradeCandle(index: i, open: 100, high: 101, low: 99, close: 100),
  ],
  orders: const [],
  result: result,
);

final _initial = _session();
final _afterBuy = _session(cash: 8990.1, quantity: 10);
final _finished = _session(
  step: 60,
  cash: 10500,
  isFinished: true,
  result: TradeResult(
    symbol: 'AAPL',
    startDay: DateTime.utc(2026, 1, 2),
    endDay: DateTime.utc(2026, 6, 30),
    endIndex: 119,
    finalEquity: 10500,
    returnPct: 5,
    buyHoldReturnPct: 2,
    maxDrawdownPct: 3,
    tradeCount: 2,
  ),
);

void main() {
  late _MockTradeUseCase useCase;

  setUpAll(() => registerFallbackValue(TradeSide.buy));

  setUp(() => useCase = _MockTradeUseCase());

  void stubPlaceOrder(Result<TradeSession> result) => when(
    () => useCase.placeOrder(
      sessionId: any(named: 'sessionId'),
      side: any(named: 'side'),
      quantity: any(named: 'quantity'),
    ),
  ).thenAnswer((_) async => result);

  group('load', () {
    blocTest<TradeSessionCubit, TradeSessionState>(
      '판을 읽어 담는다',
      build: () {
        when(
          () => useCase.getSession(any()),
        ).thenAnswer((_) async => Ok(_initial));
        return TradeSessionCubit(useCase);
      },
      act: (cubit) => cubit.load('session-1'),
      expect: () => [
        const TradeSessionState.loading(),
        TradeSessionState.loaded(session: _initial),
      ],
      verify: (_) => verify(() => useCase.getSession('session-1')).called(1),
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '없는 판은 실패로 간다',
      build: () {
        when(() => useCase.getSession(any())).thenAnswer(
          (_) async => const Err(
            Failure.notFound(failureCode: FailureCode.tradeSessionNotFound),
          ),
        );
        return TradeSessionCubit(useCase);
      },
      act: (cubit) => cubit.load('gone'),
      expect: () => [
        const TradeSessionState.loading(),
        const TradeSessionState.failure(
          Failure.notFound(failureCode: FailureCode.tradeSessionNotFound),
        ),
      ],
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '끝난 판도 같은 조회로 읽는다 — 결과 화면이 쓰는 경로다',
      build: () {
        when(
          () => useCase.getSession(any()),
        ).thenAnswer((_) async => Ok(_finished));
        return TradeSessionCubit(useCase);
      },
      act: (cubit) => cubit.load('session-1'),
      expect: () => [
        const TradeSessionState.loading(),
        TradeSessionState.loaded(session: _finished),
      ],
    );
  });

  group('placeOrder', () {
    late Result<TradeSession> firstResult;
    late Result<TradeSession> secondResult;

    blocTest<TradeSessionCubit, TradeSessionState>(
      '주문이 끝나면 서버가 준 판으로 통째로 바꾼다',
      build: () {
        stubPlaceOrder(Ok(_afterBuy));
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) async => firstResult = await cubit.placeOrder(
        side: TradeSide.buy,
        quantity: 10,
      ),
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        TradeSessionState.loaded(session: _afterBuy),
      ],
      verify: (_) {
        expect((firstResult as Ok<TradeSession>).value, _afterBuy);
        verify(
          () => useCase.placeOrder(
            sessionId: 'session-1',
            side: TradeSide.buy,
            quantity: 10,
          ),
        ).called(1);
      },
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '실패하면 판은 그대로 두고 Result 로 돌려준다',
      build: () {
        stubPlaceOrder(
          const Err(
            Failure.validation(failureCode: FailureCode.tradeInsufficientCash),
          ),
        );
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) async => firstResult = await cubit.placeOrder(
        side: TradeSide.buy,
        quantity: 999999,
      ),
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        TradeSessionState.loaded(session: _initial),
      ],
      verify: (_) => expect(
        (firstResult as Err<TradeSession>).failure.failureCode,
        FailureCode.tradeInsufficientCash,
      ),
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '진행 중에 또 누르면 무시한다',
      build: () {
        stubPlaceOrder(Ok(_afterBuy));
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) async {
        final first = cubit.placeOrder(side: TradeSide.buy, quantity: 10);
        secondResult = await cubit.placeOrder(
          side: TradeSide.buy,
          quantity: 10,
        );
        firstResult = await first;
      },
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        TradeSessionState.loaded(session: _afterBuy),
      ],
      verify: (_) {
        expect(firstResult, isA<Ok<TradeSession>>());
        expect(
          (secondResult as Err<TradeSession>).failure.failureCode,
          FailureCode.operationInProgress,
        );
        verify(
          () => useCase.placeOrder(
            sessionId: any(named: 'sessionId'),
            side: any(named: 'side'),
            quantity: any(named: 'quantity'),
          ),
        ).called(1);
      },
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '주문이 날아가 있는 동안 다시 읽으면 늦게 온 응답은 버린다',
      build: () {
        stubPlaceOrder(Ok(_afterBuy));
        when(
          () => useCase.getSession(any()),
        ).thenAnswer((_) async => Ok(_finished));
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) async {
        final order = cubit.placeOrder(side: TradeSide.buy, quantity: 10);
        await cubit.load('session-1');
        firstResult = await order;
      },
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        const TradeSessionState.loading(),
        TradeSessionState.loaded(session: _finished),
      ],
      verify: (_) => expect(firstResult, isA<Ok<TradeSession>>()),
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '아직 판을 읽지 못했으면 주문하지 않는다',
      build: () => TradeSessionCubit(useCase),
      act: (cubit) async => firstResult = await cubit.placeOrder(
        side: TradeSide.buy,
        quantity: 1,
      ),
      expect: () => <TradeSessionState>[],
      verify: (_) {
        expect(
          (firstResult as Err<TradeSession>).failure.failureCode,
          FailureCode.operationInProgress,
        );
        verifyNever(
          () => useCase.placeOrder(
            sessionId: any(named: 'sessionId'),
            side: any(named: 'side'),
            quantity: any(named: 'quantity'),
          ),
        );
      },
    );
  });

  group('advance', () {
    late Result<TradeSession> result;

    blocTest<TradeSessionCubit, TradeSessionState>(
      '다음 step 의 판으로 바꾼다',
      build: () {
        when(
          () => useCase.advance(any()),
        ).thenAnswer((_) async => Ok(_session(step: 4)));
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) => cubit.advance(),
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        TradeSessionState.loaded(session: _session(step: 4)),
      ],
      verify: (_) => verify(() => useCase.advance('session-1')).called(1),
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '자동 종료된 판이 와도 loaded 로 둔다 — 결과로 보낼지는 화면이 정한다',
      build: () {
        when(
          () => useCase.advance(any()),
        ).thenAnswer((_) async => Ok(_finished));
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _session(step: 59)),
      act: (cubit) async => result = await cubit.advance(),
      expect: () => [
        TradeSessionState.loaded(
          session: _session(step: 59),
          isSubmitting: true,
        ),
        TradeSessionState.loaded(session: _finished),
      ],
      verify: (_) =>
          expect((result as Ok<TradeSession>).value.isFinished, isTrue),
    );

    blocTest<TradeSessionCubit, TradeSessionState>(
      '이미 끝난 판이라는 실패는 판을 그대로 두고 돌려준다',
      build: () {
        when(() => useCase.advance(any())).thenAnswer(
          (_) async => const Err(
            Failure.validation(failureCode: FailureCode.tradeSessionFinished),
          ),
        );
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) async => result = await cubit.advance(),
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        TradeSessionState.loaded(session: _initial),
      ],
      verify: (_) => expect(
        (result as Err<TradeSession>).failure.failureCode,
        FailureCode.tradeSessionFinished,
      ),
    );
  });

  group('finish', () {
    late Result<TradeSession> result;

    blocTest<TradeSessionCubit, TradeSessionState>(
      '중간에 끝내면 결과가 붙은 판으로 바뀐다',
      build: () {
        when(
          () => useCase.finish(any()),
        ).thenAnswer((_) async => Ok(_finished));
        return TradeSessionCubit(useCase);
      },
      seed: () => TradeSessionState.loaded(session: _initial),
      act: (cubit) async => result = await cubit.finish(),
      expect: () => [
        TradeSessionState.loaded(session: _initial, isSubmitting: true),
        TradeSessionState.loaded(session: _finished),
      ],
      verify: (_) {
        expect((result as Ok<TradeSession>).value.result, isNotNull);
        verify(() => useCase.finish('session-1')).called(1);
      },
    );
  });
}
