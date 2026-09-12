import 'package:daylog/app/router/routes.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/trade/domain/entity/trade_result_summary.dart';
import 'package:daylog/features/trade/domain/entity/trade_candle.dart';
import 'package:daylog/features/trade/domain/entity/trade_order.dart';
import 'package:daylog/features/trade/domain/entity/trade_result.dart';
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:daylog/features/trade/domain/trade_rules.dart';
import 'package:daylog/features/trade/domain/usecase/trade_use_case.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_session_cubit.dart';
import 'package:daylog/features/trade/presentation/page/trade_result_page.dart';
import 'package:daylog/features/trade/presentation/widget/trade_candle_chart.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeUseCase extends Mock implements TradeUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');

TradeSession _finished({
  double returnPct = 12.34,
  double buyHoldReturnPct = 3,
  String userId = 'me',
}) => TradeSession(
  id: 's1',
  userId: userId,
  step: TradeRules.tradeSteps,
  cash: 11234,
  quantity: 0,
  isFinished: true,
  candles: [
    for (var i = 0; i < TradeRules.totalCandles; i++)
      TradeCandle(index: i, open: 100, high: 101, low: 99, close: 100),
  ],
  orders: const [
    TradeOrder(step: 2, side: TradeSide.buy, quantity: 10, price: 100, fee: 1),
  ],
  result: TradeResult(
    symbol: 'BTCUSDT',
    startDay: DateTime.utc(2021, 11),
    endDay: DateTime.utc(2022, 1, 29),
    endIndex: TradeRules.totalCandles - 1,
    finalEquity: 11234,
    returnPct: returnPct,
    buyHoldReturnPct: buyHoldReturnPct,
    maxDrawdownPct: 8,
    tradeCount: 4,
  ),
);

TradeSession _running() => TradeSession(
  id: 's1',
  userId: 'me',
  step: 3,
  cash: TradeRules.initialCash,
  quantity: 0,
  isFinished: false,
  candles: [
    for (var i = 0; i <= TradeRules.indexForStep(3); i++)
      TradeCandle(index: i, open: 100, high: 101, low: 99, close: 100),
  ],
  orders: const [],
);

void main() {
  late _MockTradeUseCase useCase;
  late _MockAuthBloc authBloc;

  setUp(() {
    useCase = _MockTradeUseCase();
    authBloc = _MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    getIt.registerFactory<TradeSessionCubit>(() => TradeSessionCubit(useCase));
  });

  tearDown(getIt.reset);

  /// 결과 화면은 공유하기로 작성 화면을 push 한다. 그래서 라우터 위에서
  /// 띄우고, 갈 곳을 하나 둔다.
  Future<GoRouter> pumpResult(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.tradeResultPath('s1'),
      routes: [
        GoRoute(
          path: Routes.tradeResult,
          builder: (_, state) =>
              TradeResultPage(sessionId: state.pathParameters['sessionId']!),
        ),
        GoRoute(
          path: Routes.postCompose,
          // app_router.dart 의 실제 builder 와 같은 모양이다: extra 는
          // TradeResultSummary 가 아니라 JSON 호환 Map 으로 오고, 여기서
          // fromMap 으로 되돌려 미리보기를 그린다.
          builder: (_, state) {
            final summary = TradeResultSummary.fromMap(state.extra);
            return Scaffold(
              body: Center(
                child: Text(
                  summary == null ? '작성' : '작성 · ${summary.displaySymbol}',
                ),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다.
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (_, child) =>
            BlocProvider<AuthBloc>.value(value: authBloc, child: child!),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('끝난 판은 종목 · 기간과 지표 네 개를 보여준다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_finished()));

    await pumpResult(tester);

    expect(find.text('결과'), findsOneWidget);
    // 종목과 기간은 판이 끝나야 공개된다. USDT 접미는 떼고 보여준다.
    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);

    expect(find.text('수익률'), findsOneWidget);
    expect(find.text('+12.34%'), findsOneWidget);
    expect(find.text('보유만 했을 때'), findsOneWidget);
    expect(find.text('+3.00%'), findsOneWidget);
    expect(find.text('최대낙폭'), findsOneWidget);
    // 낙폭은 0 이상으로 오지만 아래로 내려간 폭이라 음수로 찍는다.
    expect(find.text('−8.00%'), findsOneWidget);
    expect(find.text('매매 횟수'), findsOneWidget);
    expect(find.text('4회'), findsOneWidget);

    expect(find.byType(TradeCandleChart), findsOneWidget);
  });

  testWidgets('보유보다 나았으면 그렇게 한 줄로 말한다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_finished()));

    await pumpResult(tester);

    expect(find.text('보유보다 9.34% 나았습니다'), findsOneWidget);
  });

  testWidgets('보유보다 못했으면 그렇게 한 줄로 말한다', (tester) async {
    when(() => useCase.getSession(any())).thenAnswer(
      (_) async => Ok(_finished(returnPct: -5.1, buyHoldReturnPct: 3)),
    );

    await pumpResult(tester);

    expect(find.text('−5.10%'), findsOneWidget);
    expect(find.text('보유보다 8.10% 못했습니다'), findsOneWidget);
  });

  testWidgets('아직 끝나지 않은 판은 지표 대신 안내를 보여준다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_running()));

    await pumpResult(tester);

    expect(find.text('아직 끝나지 않은 판입니다'), findsOneWidget);
    expect(find.text('수익률'), findsNothing);
    expect(find.byType(TradeCandleChart), findsNothing);
  });

  testWidgets('조회가 실패하면 다시 시도를 보여준다', (tester) async {
    when(() => useCase.getSession(any())).thenAnswer(
      (_) async => const Err(Failure.notFound(message: '판을 찾을 수 없습니다')),
    );

    await pumpResult(tester);

    expect(find.text('판을 찾을 수 없습니다'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_finished()));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
  });

  testWidgets('내 판이면 공유하기로 작성 화면에 결과를 들려 보낸다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_finished()));

    final router = await pumpResult(tester);

    expect(find.text('공유하기'), findsOneWidget);

    await tester.tap(find.text('공유하기'));
    await tester.pumpAndSettle();

    expect(router.state.matchedLocation, Routes.postCompose);
    // TradeResultSummary 자체가 아니라 JSON 호환 Map 이다 — go_router 가
    // codec 없는 클래스를 extra 로 만나면 상태 복원 시도에서 경고를 낸다.
    final extra = router.state.extra! as Map<String, Object?>;
    expect(extra, {
      'session_id': 's1',
      'symbol': 'BTCUSDT',
      'start_day': '2021-11-01',
      'end_day': '2022-01-29',
      'return_pct': 12.34,
      'buy_hold_return_pct': 3.0,
      'max_drawdown_pct': 8.0,
      'trade_count': 4,
    });
    // 작성 화면의 라우터 builder 가 그 Map 을 도로 TradeResultSummary 로
    // 풀어 미리보기를 그린다.
    expect(find.text('작성 · BTC'), findsOneWidget);
  });

  testWidgets('남의 판에는 공유하기가 없다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_finished(userId: 'other')));

    await pumpResult(tester);

    expect(find.text('+12.34%'), findsOneWidget);
    expect(find.text('공유하기'), findsNothing);
  });

  testWidgets('게스트에게도 공유하기가 없다', (tester) async {
    // 공유 링크를 타고 들어온 비로그인 사용자다. 결과는 보이되 올릴 수는 없다.
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_finished()));

    await pumpResult(tester);

    expect(find.text('+12.34%'), findsOneWidget);
    expect(find.text('공유하기'), findsNothing);
  });
}
