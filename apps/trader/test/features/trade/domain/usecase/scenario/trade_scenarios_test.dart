import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/error/failure_code.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_session_summary.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:daylog/features/trade/domain/repository/trade_repository.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/advance_trade_session_scenario.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/finish_trade_session_scenario.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/get_active_trade_session_scenario.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/get_past_trade_sessions_scenario.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/get_trade_session_scenario.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/place_trade_order_scenario.dart';
import 'package:daylog/features/trade/domain/usecase/scenario/start_trade_session_scenario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeRepository extends Mock implements TradeRepository {}

const _session = TradeSession(
  id: 's1',
  userId: 'u1',
  step: 1,
  cash: 10000,
  quantity: 0,
  isFinished: false,
  candles: [],
  orders: [],
);

const _emptyPage = Ok(CursorPage<TradeSessionSummary>(items: []));

void main() {
  late _MockTradeRepository repository;

  setUpAll(() {
    registerFallbackValue(TradeSide.buy);
  });

  setUp(() => repository = _MockTradeRepository());

  group('StartTradeSessionScenario', () {
    test('저장소로 그대로 위임한다', () async {
      when(
        () => repository.startSession(),
      ).thenAnswer((_) async => const Ok('s1'));

      final result = await StartTradeSessionScenario(repository)();

      expect((result as Ok).value, 's1');
      verify(() => repository.startSession()).called(1);
    });
  });

  group('GetTradeSessionScenario', () {
    test('정상 id 는 저장소로 위임한다', () async {
      when(
        () => repository.getSession('s1'),
      ).thenAnswer((_) async => const Ok(_session));

      final result = await GetTradeSessionScenario(repository)('s1');

      expect((result as Ok).value, _session);
      verify(() => repository.getSession('s1')).called(1);
    });

    test('빈 id 는 저장소를 부르지 않는다', () async {
      for (final id in ['', '   ']) {
        final result = await GetTradeSessionScenario(repository)(id);

        expect(
          (result as Err).failure,
          isA<ValidationFailure>().having(
            (f) => f.failureCode,
            'failureCode',
            FailureCode.tradeSessionNotFound,
          ),
        );
      }
      verifyNever(() => repository.getSession(any()));
    });
  });

  group('GetActiveTradeSessionScenario', () {
    test('저장소로 그대로 위임한다', () async {
      when(
        () => repository.getActiveSession(),
      ).thenAnswer((_) async => const Ok(null));

      final result = await GetActiveTradeSessionScenario(repository)();

      expect((result as Ok).value, isNull);
      verify(() => repository.getActiveSession()).called(1);
    });
  });

  group('PlaceTradeOrderScenario', () {
    test('정상 요청은 저장소로 위임한다', () async {
      when(
        () => repository.placeOrder(
          sessionId: 's1',
          side: TradeSide.buy,
          quantity: 1.5,
        ),
      ).thenAnswer((_) async => const Ok(_session));

      final result = await PlaceTradeOrderScenario(repository)(
        sessionId: 's1',
        side: TradeSide.buy,
        quantity: 1.5,
      );

      expect((result as Ok).value, _session);
      verify(
        () => repository.placeOrder(
          sessionId: 's1',
          side: TradeSide.buy,
          quantity: 1.5,
        ),
      ).called(1);
    });

    test('빈 id 는 저장소를 부르지 않는다', () async {
      final result = await PlaceTradeOrderScenario(repository)(
        sessionId: '  ',
        side: TradeSide.buy,
        quantity: 1,
      );

      expect(
        (result as Err).failure,
        isA<ValidationFailure>().having(
          (f) => f.failureCode,
          'failureCode',
          FailureCode.tradeSessionNotFound,
        ),
      );
      verifyNever(
        () => repository.placeOrder(
          sessionId: any(named: 'sessionId'),
          side: any(named: 'side'),
          quantity: any(named: 'quantity'),
        ),
      );
    });

    test('0 이하이거나 NaN·Infinity 인 수량은 저장소를 부르지 않는다', () async {
      for (final quantity in [
        0.0,
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final result = await PlaceTradeOrderScenario(repository)(
          sessionId: 's1',
          side: TradeSide.sell,
          quantity: quantity,
        );

        expect(
          (result as Err).failure,
          isA<ValidationFailure>().having(
            (f) => f.failureCode,
            'failureCode',
            FailureCode.tradeQuantityInvalid,
          ),
        );
      }
      verifyNever(
        () => repository.placeOrder(
          sessionId: any(named: 'sessionId'),
          side: any(named: 'side'),
          quantity: any(named: 'quantity'),
        ),
      );
    });
  });

  group('AdvanceTradeSessionScenario', () {
    test('정상 id 는 저장소로 위임한다', () async {
      when(
        () => repository.advance('s1'),
      ).thenAnswer((_) async => const Ok(_session));

      final result = await AdvanceTradeSessionScenario(repository)('s1');

      expect((result as Ok).value, _session);
      verify(() => repository.advance('s1')).called(1);
    });

    test('빈 id 는 저장소를 부르지 않는다', () async {
      final result = await AdvanceTradeSessionScenario(repository)('');

      expect((result as Err).failure, isA<ValidationFailure>());
      verifyNever(() => repository.advance(any()));
    });
  });

  group('FinishTradeSessionScenario', () {
    test('정상 id 는 저장소로 위임한다', () async {
      when(
        () => repository.finish('s1'),
      ).thenAnswer((_) async => const Ok(_session));

      final result = await FinishTradeSessionScenario(repository)('s1');

      expect((result as Ok).value, _session);
      verify(() => repository.finish('s1')).called(1);
    });

    test('빈 id 는 저장소를 부르지 않는다', () async {
      final result = await FinishTradeSessionScenario(repository)('   ');

      expect((result as Err).failure, isA<ValidationFailure>());
      verifyNever(() => repository.finish(any()));
    });
  });

  group('GetPastTradeSessionsScenario', () {
    test('정상 범위는 커서를 그대로 넘긴다', () async {
      when(
        () => repository.getPastSessions(limit: 20, cursor: 'cursor-token'),
      ).thenAnswer((_) async => _emptyPage);

      await GetPastTradeSessionsScenario(repository)(
        limit: 20,
        cursor: 'cursor-token',
      );

      verify(
        () => repository.getPastSessions(limit: 20, cursor: 'cursor-token'),
      ).called(1);
    });

    test('허용 범위를 벗어난 개수는 저장소를 부르지 않는다', () async {
      for (final limit in [
        0,
        -1,
        GetPastTradeSessionsScenario.maxPageSize + 1,
      ]) {
        final result = await GetPastTradeSessionsScenario(repository)(
          limit: limit,
        );

        expect(
          (result as Err).failure,
          isA<ValidationFailure>().having(
            (f) => f.failureCode,
            'failureCode',
            FailureCode.feedRangeInvalid,
          ),
        );
      }
      verifyNever(
        () => repository.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      );
    });
  });
}
