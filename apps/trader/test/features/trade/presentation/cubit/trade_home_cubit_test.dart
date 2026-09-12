import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/error/failure_code.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/features/trade/domain/entity/trade_candle.dart';
import 'package:daylog/features/trade/domain/entity/trade_result.dart';
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_session_summary.dart';
import 'package:daylog/features/trade/domain/trade_rules.dart';
import 'package:daylog/features/trade/domain/usecase/trade_use_case.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_home_cubit.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeUseCase extends Mock implements TradeUseCase {}

TradeSession _session({String id = 'active-1', int step = 3}) => TradeSession(
  id: id,
  userId: 'user-1',
  step: step,
  cash: TradeRules.initialCash,
  quantity: 0,
  isFinished: false,
  candles: [
    for (var i = 0; i <= TradeRules.indexForStep(step); i++)
      TradeCandle(index: i, open: 100, high: 101, low: 99, close: 100),
  ],
  orders: const [],
);

TradeSessionSummary _summary(String id) => TradeSessionSummary(
  id: id,
  createdAt: DateTime.utc(2026, 9, 1, 9),
  finishedAt: DateTime.utc(2026, 9, 1, 10),
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

final _active = _session();

void main() {
  late _MockTradeUseCase useCase;

  setUp(() => useCase = _MockTradeUseCase());

  void stubLoad({
    TradeSession? active,
    List<TradeSessionSummary> past = const [],
    String? nextCursor,
  }) {
    when(
      () => useCase.getActiveSession(),
    ).thenAnswer((_) async => Ok<TradeSession?>(active));
    when(
      () => useCase.getPastSessions(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => Ok(
        CursorPage<TradeSessionSummary>(items: past, nextCursor: nextCursor),
      ),
    );
  }

  group('load', () {
    blocTest<TradeHomeCubit, TradeHomeState>(
      '진행 중인 판과 지난 판을 함께 담는다',
      build: () {
        stubLoad(active: _active, past: [_summary('p1')], nextCursor: 'c1');
        return TradeHomeCubit(useCase);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const TradeHomeState.loading(),
        TradeHomeState.loaded(
          active: _active,
          past: [_summary('p1')],
          nextCursor: 'c1',
        ),
      ],
      verify: (_) {
        verify(() => useCase.getActiveSession()).called(1);
        verify(
          () => useCase.getPastSessions(limit: 20, cursor: null),
        ).called(1);
      },
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '진행 중인 판이 없으면 active 가 비어 있다',
      build: () {
        stubLoad(past: [_summary('p1')]);
        return TradeHomeCubit(useCase);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const TradeHomeState.loading(),
        TradeHomeState.loaded(past: [_summary('p1')]),
      ],
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '진행 중인 판 조회가 실패하면 실패로 간다',
      build: () {
        stubLoad(past: [_summary('p1')]);
        when(
          () => useCase.getActiveSession(),
        ).thenAnswer((_) async => const Err(Failure.network()));
        return TradeHomeCubit(useCase);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const TradeHomeState.loading(),
        const TradeHomeState.failure(Failure.network()),
      ],
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '지난 판 조회가 실패하면 진행 중인 판이 있어도 실패로 간다',
      build: () {
        stubLoad(active: _active);
        when(
          () => useCase.getPastSessions(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer((_) async => const Err(Failure.server()));
        return TradeHomeCubit(useCase);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const TradeHomeState.loading(),
        const TradeHomeState.failure(Failure.server()),
      ],
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      'refresh 는 같은 조회를 다시 돈다',
      build: () {
        stubLoad(past: [_summary('p1')]);
        return TradeHomeCubit(useCase);
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const TradeHomeState.loading(),
        TradeHomeState.loaded(past: [_summary('p1')]),
      ],
      verify: (_) => verify(
        () => useCase.getPastSessions(limit: 20, cursor: null),
      ).called(1),
    );
  });

  group('loadMore', () {
    blocTest<TradeHomeCubit, TradeHomeState>(
      '다음 페이지를 지난 판 뒤에 이어 붙인다',
      build: () {
        when(
          () => useCase.getPastSessions(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer(
          (_) async =>
              Ok(CursorPage<TradeSessionSummary>(items: [_summary('p2')])),
        );
        return TradeHomeCubit(useCase);
      },
      seed: () =>
          TradeHomeState.loaded(past: [_summary('p1')], nextCursor: 'c1'),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        TradeHomeState.loaded(
          past: [_summary('p1')],
          nextCursor: 'c1',
          isLoadingMore: true,
        ),
        TradeHomeState.loaded(past: [_summary('p1'), _summary('p2')]),
      ],
      verify: (_) => verify(
        () => useCase.getPastSessions(limit: 20, cursor: 'c1'),
      ).called(1),
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '실패하면 목록은 그대로 두고 더 읽기만 끈다',
      build: () {
        when(
          () => useCase.getPastSessions(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer((_) async => const Err(Failure.network()));
        return TradeHomeCubit(useCase);
      },
      seed: () =>
          TradeHomeState.loaded(past: [_summary('p1')], nextCursor: 'c1'),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        TradeHomeState.loaded(
          past: [_summary('p1')],
          nextCursor: 'c1',
          isLoadingMore: true,
        ),
        TradeHomeState.loaded(past: [_summary('p1')], nextCursor: 'c1'),
      ],
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '커서가 없으면 읽지 않는다',
      build: () => TradeHomeCubit(useCase),
      seed: () => TradeHomeState.loaded(past: [_summary('p1')]),
      act: (cubit) => cubit.loadMore(),
      expect: () => <TradeHomeState>[],
      verify: (_) => verifyNever(
        () => useCase.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ),
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '이미 더 읽는 중이면 다시 읽지 않는다',
      build: () => TradeHomeCubit(useCase),
      seed: () => TradeHomeState.loaded(
        past: [_summary('p1')],
        nextCursor: 'c1',
        isLoadingMore: true,
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => <TradeHomeState>[],
      verify: (_) => verifyNever(
        () => useCase.getPastSessions(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ),
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '읽는 중에 load 가 목록을 갈아치우면 늦게 온 페이지는 버린다',
      build: () {
        when(
          () => useCase.getActiveSession(),
        ).thenAnswer((_) async => const Ok<TradeSession?>(null));
        when(
          () => useCase.getPastSessions(
            limit: any(named: 'limit'),
            cursor: 'c1',
          ),
        ).thenAnswer(
          (_) async =>
              Ok(CursorPage<TradeSessionSummary>(items: [_summary('p2')])),
        );
        when(
          () =>
              useCase.getPastSessions(limit: any(named: 'limit'), cursor: null),
        ).thenAnswer(
          (_) async =>
              Ok(CursorPage<TradeSessionSummary>(items: [_summary('p3')])),
        );
        return TradeHomeCubit(useCase);
      },
      seed: () =>
          TradeHomeState.loaded(past: [_summary('p1')], nextCursor: 'c1'),
      act: (cubit) async {
        final more = cubit.loadMore();
        await cubit.load();
        await more;
      },
      expect: () => [
        TradeHomeState.loaded(
          past: [_summary('p1')],
          nextCursor: 'c1',
          isLoadingMore: true,
        ),
        const TradeHomeState.loading(),
        TradeHomeState.loaded(past: [_summary('p3')]),
      ],
    );
  });

  group('start', () {
    late Result<String> firstResult;
    late Result<String> secondResult;

    blocTest<TradeHomeCubit, TradeHomeState>(
      '시작하는 동안 잠그고, 성공하면 홈을 다시 읽는다',
      build: () {
        when(
          () => useCase.startSession(),
        ).thenAnswer((_) async => const Ok('new-1'));
        stubLoad(active: _active, past: [_summary('p1')]);
        return TradeHomeCubit(useCase);
      },
      seed: () => TradeHomeState.loaded(past: [_summary('p1')]),
      act: (cubit) async => firstResult = await cubit.start(),
      expect: () => [
        TradeHomeState.loaded(past: [_summary('p1')], isStarting: true),
        const TradeHomeState.loading(),
        TradeHomeState.loaded(active: _active, past: [_summary('p1')]),
      ],
      verify: (_) {
        expect((firstResult as Ok<String>).value, 'new-1');
        verify(() => useCase.startSession()).called(1);
        verify(() => useCase.getActiveSession()).called(1);
      },
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '실패하면 잠금을 풀고 Result 로 돌려준다',
      build: () {
        when(() => useCase.startSession()).thenAnswer(
          (_) async => const Err(
            Failure.validation(
              failureCode: FailureCode.tradeSessionAlreadyActive,
            ),
          ),
        );
        return TradeHomeCubit(useCase);
      },
      seed: () => TradeHomeState.loaded(past: [_summary('p1')]),
      act: (cubit) async => firstResult = await cubit.start(),
      expect: () => [
        TradeHomeState.loaded(past: [_summary('p1')], isStarting: true),
        TradeHomeState.loaded(past: [_summary('p1')]),
      ],
      verify: (_) {
        expect(
          (firstResult as Err<String>).failure.failureCode,
          FailureCode.tradeSessionAlreadyActive,
        );
        verifyNever(() => useCase.getActiveSession());
      },
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '연타해도 판은 하나만 만든다',
      build: () {
        when(
          () => useCase.startSession(),
        ).thenAnswer((_) async => const Ok('new-1'));
        stubLoad(active: _active);
        return TradeHomeCubit(useCase);
      },
      seed: () => const TradeHomeState.loaded(),
      act: (cubit) async {
        final first = cubit.start();
        secondResult = await cubit.start();
        firstResult = await first;
      },
      verify: (_) {
        expect((firstResult as Ok<String>).value, 'new-1');
        expect(
          (secondResult as Err<String>).failure.failureCode,
          FailureCode.operationInProgress,
        );
        verify(() => useCase.startSession()).called(1);
      },
    );

    blocTest<TradeHomeCubit, TradeHomeState>(
      '아직 읽는 중이면 시작하지 않는다',
      build: () => TradeHomeCubit(useCase),
      act: (cubit) async => firstResult = await cubit.start(),
      expect: () => <TradeHomeState>[],
      verify: (_) {
        expect(
          (firstResult as Err<String>).failure.failureCode,
          FailureCode.operationInProgress,
        );
        verifyNever(() => useCase.startSession());
      },
    );
  });

  test('canLoadMore 는 커서가 남아 있을 때만 참이다', () {
    expect(const TradeHomeState.loaded(nextCursor: 'c1').canLoadMore, isTrue);
    expect(const TradeHomeState.loaded().canLoadMore, isFalse);
    expect(const TradeHomeState.loading().canLoadMore, isFalse);
  });
}
