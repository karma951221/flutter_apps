import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:daylog/features/trade/domain/entity/trade_candle.dart';
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_session_summary.dart';
import 'package:daylog/features/trade/domain/entity/trade_side.dart';
import 'package:daylog/features/trade/domain/ledger/trade_cost.dart';
import 'package:daylog/features/trade/domain/ledger/trade_sizing.dart';
import 'package:daylog/features/trade/domain/trade_rules.dart';
import 'package:daylog/features/trade/domain/usecase/trade_use_case.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_home_cubit.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_session_cubit.dart';
import 'package:daylog/features/trade/presentation/format/trade_format.dart';
import 'package:daylog/features/trade/presentation/page/trade_home_page.dart';
import 'package:daylog/features/trade/presentation/page/trade_session_page.dart';
import 'package:daylog/features/trade/presentation/widget/trade_candle_chart.dart';
import 'package:daylog/features/trade/presentation/widget/trade_order_sheet.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeUseCase extends Mock implements TradeUseCase {}

TradeSession _session({
  int step = 3,
  double cash = TradeRules.initialCash,
  double quantity = 0,
  double close = 100,
  bool isFinished = false,
}) => TradeSession(
  id: 's1',
  userId: 'me',
  step: step,
  cash: cash,
  quantity: quantity,
  isFinished: isFinished,
  candles: [
    for (var i = 0; i <= TradeRules.indexForStep(step); i++)
      TradeCandle(
        index: i,
        open: close,
        high: close + 1,
        low: close - 1,
        close: close,
      ),
  ],
  orders: const [],
);

void main() {
  late _MockTradeUseCase useCase;

  setUpAll(() {
    registerFallbackValue(TradeSide.buy);
  });

  setUp(() {
    useCase = _MockTradeUseCase();
    getIt.registerFactory<TradeSessionCubit>(() => TradeSessionCubit(useCase));
  });

  tearDown(getIt.reset);

  /// 홈에서 판으로 들어간 상태를 만든다.
  ///
  /// 실제 앱에서 판 화면은 홈이 `push` 해서 열고, 홈은 그 위가 걷히는 순간을
  /// [appRouteObserver] 로 듣는다. 화면이 어떻게 빠져나가느냐가 스택의 모양을
  /// 가르므로 테스트도 같은 모양으로 쌓고 같은 observer 를 단다.
  ///
  /// [fromHome] 이 false 면 판 화면이 스택의 바닥이다 — 링크로 곧장 열린 경우.
  ///
  /// 홈과 결과 화면은 이 태스크의 범위가 아니라 표시만 하는 라우트로 대신한다.
  /// [visited] 는 마지막으로 들어간 결과 경로를 돌려준다.
  Future<({GoRouter router, String? Function() visited})> pumpSession(
    WidgetTester tester, {
    bool fromHome = true,
  }) async {
    // 기본 800×600 에서는 차트와 지표가 스크롤 밖으로 밀려 조회되지 않는다.
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? visited;
    final router = GoRouter(
      initialLocation: fromHome ? Routes.home : Routes.tradeSessionPath('s1'),
      observers: [appRouteObserver],
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('홈 화면')),
        ),
        GoRoute(
          path: Routes.tradeSession,
          builder: (_, state) =>
              TradeSessionPage(sessionId: state.pathParameters['sessionId']!),
        ),
        GoRoute(
          path: Routes.tradeResult,
          builder: (_, state) {
            visited = state.matchedLocation;
            return const Scaffold(body: Text('결과 화면'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다.
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    if (fromHome) {
      // 판이 결과로 갈아치워지면 이 future 는 영영 끝나지 않는다. 기다리면
      // 테스트가 그 자리에 선다.
      unawaited(router.push(Routes.tradeSessionPath('s1')));
      await tester.pumpAndSettle();
    }

    return (router: router, visited: () => visited);
  }

  testWidgets('지표 네 칸과 현재가를 보여준다', (tester) async {
    when(() => useCase.getSession(any())).thenAnswer(
      (_) async => Ok(_session(cash: 10000, quantity: 0.5, close: 120)),
    );

    await pumpSession(tester);

    expect(find.text('모의투자'), findsOneWidget);
    expect(find.text('3 / 60'), findsOneWidget);
    expect(find.byType(TradeCandleChart), findsOneWidget);

    // 현재가는 단위 없는 정규화 종가다.
    expect(find.text('현재가'), findsOneWidget);
    expect(find.text('120.00'), findsOneWidget);

    expect(find.text('현금'), findsOneWidget);
    expect(find.text('10,000.00'), findsOneWidget);
    expect(find.text('보유 수량'), findsOneWidget);
    // 소수 6자리까지 찍되 뒤의 0 은 떼어 낸다.
    expect(find.text('0.5'), findsOneWidget);
    expect(find.text('평가액'), findsOneWidget);
    // 10000 + 0.5 × 120
    expect(find.text('10,060.00'), findsOneWidget);
    expect(find.text('현재 수익률'), findsOneWidget);
    expect(find.text('+0.60%'), findsOneWidget);
  });

  testWidgets('진행 중인 판은 심볼도 날짜도 그리지 않는다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(quantity: 2, close: 137.25)));

    await pumpSession(tester);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .toList();
    expect(texts, isNotEmpty);
    expect(
      texts.where((text) => text.contains('USDT')),
      isEmpty,
      reason: '판이 끝나기 전에는 종목이 드러나면 안 된다',
    );
    expect(
      texts.where((text) => RegExp(r'20\d\d-').hasMatch(text)),
      isEmpty,
      reason: '판이 끝나기 전에는 날짜가 드러나면 안 된다',
    );
  });

  testWidgets('매수 시트에서 50% 를 누르면 TradeSizing 과 같은 값을 미리 보여준다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(cash: 10000, close: 100)));
    when(
      () => useCase.placeOrder(
        sessionId: any(named: 'sessionId'),
        side: any(named: 'side'),
        quantity: any(named: 'quantity'),
      ),
    ).thenAnswer((_) async => Ok(_session(cash: 5000, quantity: 49.950049)));

    await pumpSession(tester);
    await tester.tap(find.text('매수'));
    await tester.pumpAndSettle();

    expect(find.byType(TradeOrderSheet), findsOneWidget);
    await tester.tap(find.text('50%'));
    await tester.pumpAndSettle();

    final quantity = TradeSizing.buyQuantity(
      cash: 10000,
      price: 100,
      feeRate: TradeRules.feeRate,
      fraction: 0.5,
    );
    final TradeCost cost = TradeSizing.buyCost(
      quantity: quantity,
      price: 100,
      feeRate: TradeRules.feeRate,
    );
    // 5000 / (100 × 1.001) 을 소수 6자리로 내린 값.
    expect(quantity, 49.950049);

    expect(find.text('예상 수량'), findsOneWidget);
    expect(find.text('49.950049'), findsOneWidget);
    expect(find.text('수수료'), findsOneWidget);
    expect(find.text(TradeFormat.amount(cost.fee, 'ko')), findsOneWidget);
    expect(find.text('주문 후 현금'), findsOneWidget);
    expect(
      find.text(TradeFormat.amount(10000 - cost.total, 'ko')),
      findsOneWidget,
    );

    await tester.tap(find.text('주문하기'));
    await tester.pumpAndSettle();

    verify(
      () => useCase.placeOrder(
        sessionId: 's1',
        side: TradeSide.buy,
        quantity: quantity,
      ),
    ).called(1);
    expect(find.text('주문이 체결됐습니다'), findsOneWidget);
  });

  testWidgets('주문이 거절되면 스낵바로 알리고 판은 그대로 둔다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(cash: 10000, close: 100)));
    when(
      () => useCase.placeOrder(
        sessionId: any(named: 'sessionId'),
        side: any(named: 'side'),
        quantity: any(named: 'quantity'),
      ),
    ).thenAnswer(
      (_) async => const Err(Failure.validation(message: '잔고가 부족합니다')),
    );

    await pumpSession(tester);
    await tester.tap(find.text('매수'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50%'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주문하기'));
    await tester.pumpAndSettle();

    expect(find.text('잔고가 부족합니다'), findsOneWidget);
    expect(find.text('3 / 60'), findsOneWidget);
  });

  testWidgets('다음 날을 누르면 판이 한 걸음 나아간다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session()));
    when(
      () => useCase.advance(any()),
    ).thenAnswer((_) async => Ok(_session(step: 4)));

    await pumpSession(tester);
    await tester.tap(find.text('다음 날'));
    await tester.pumpAndSettle();

    verify(() => useCase.advance('s1')).called(1);
    expect(find.text('4 / 60'), findsOneWidget);
  });

  testWidgets('보유 수량이 0 이면 매도할 수 없다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session()));

    await pumpSession(tester);

    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '매도'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '매수'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('응답을 기다리는 동안 세 버튼이 모두 잠긴다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(quantity: 1)));
    final pending = Completer<Result<TradeSession>>();
    when(() => useCase.advance(any())).thenAnswer((_) => pending.future);

    await pumpSession(tester);
    await tester.tap(find.text('다음 날'));
    await tester.pump();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음 날'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '매수'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '매도'))
          .onPressed,
      isNull,
    );

    pending.complete(Ok(_session(step: 4, quantity: 1)));
    await tester.pumpAndSettle();
  });

  testWidgets('청산하고 끝내기는 확인을 받고 판을 끝낸다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(quantity: 1)));
    when(
      () => useCase.finish(any()),
    ).thenAnswer((_) async => Ok(_session(quantity: 0, isFinished: true)));

    final harness = await pumpSession(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('청산하고 끝내기'));
    await tester.pumpAndSettle();

    expect(find.text('지금 끝낼까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '청산하고 끝내기'));
    await tester.pumpAndSettle();

    verify(() => useCase.finish('s1')).called(1);
    expect(harness.visited(), '/trade/s1/result');
  });

  testWidgets('끝난 판이 오면 결과로 넘어가고 진행 화면은 스택에 남지 않는다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(isFinished: true)));

    final harness = await pumpSession(tester);

    expect(harness.visited(), '/trade/s1/result');
    expect(harness.router.state.matchedLocation, '/trade/s1/result');
    expect(find.text('결과 화면'), findsOneWidget);
    expect(find.text('다음 날'), findsNothing);

    // 결과에서 뒤로 나오면 곧장 홈이다 — 매매 버튼이 살아 있는 화면은 그
    // 사이에 없다.
    harness.router.pop();
    await tester.pumpAndSettle();

    expect(find.text('홈 화면'), findsOneWidget);
    expect(find.text('다음 날'), findsNothing);
  });

  testWidgets('링크로 곧장 연 판이 끝나면 결과 화면으로 갈아탄다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(isFinished: true)));

    // 아래에 아무것도 없는 자리라 갈아탄 결과가 스택의 바닥이 된다.
    final harness = await pumpSession(tester, fromHome: false);

    expect(harness.visited(), '/trade/s1/result');
    expect(harness.router.state.matchedLocation, '/trade/s1/result');
    expect(find.text('결과 화면'), findsOneWidget);
    expect(find.text('다음 날'), findsNothing);
    // 갈아탔으므로 뒤로 나갈 곳도 없다.
    expect(harness.router.canPop(), isFalse);
  });

  testWidgets('조회가 실패하면 다시 시도를 보여준다', (tester) async {
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpSession(tester);

    expect(find.text('다시 시도'), findsOneWidget);

    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session()));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('3 / 60'), findsOneWidget);
  });

  testWidgets('홈에서 들어간 판을 끝내고 나오면 홈이 다시 읽는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    getIt.registerFactory<TradeHomeCubit>(() => TradeHomeCubit(useCase));
    when(
      () => useCase.getActiveSession(),
    ).thenAnswer((_) async => Ok<TradeSession?>(_session(quantity: 1)));
    when(
      () => useCase.getPastSessions(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => const Ok(CursorPage<TradeSessionSummary>(items: [])),
    );
    when(
      () => useCase.getSession(any()),
    ).thenAnswer((_) async => Ok(_session(quantity: 1)));
    when(
      () => useCase.finish(any()),
    ).thenAnswer((_) async => Ok(_session(quantity: 0, isFinished: true)));

    // 진짜 홈 화면 위에 판을 올린다. 홈은 자기 위가 걷히는 순간을
    // appRouteObserver 로 듣고 목록을 다시 읽으므로, 실제 앱과 같은 observer
    // 를 단 라우터로 스택을 쌓는다.
    final router = GoRouter(
      initialLocation: Routes.home,
      observers: [appRouteObserver],
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => const TradeHomePage()),
        GoRoute(
          path: Routes.tradeSession,
          builder: (_, state) =>
              TradeSessionPage(sessionId: state.pathParameters['sessionId']!),
        ),
        GoRoute(
          path: Routes.tradeResult,
          builder: (_, _) => const Scaffold(body: Text('결과 화면')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    verify(() => useCase.getActiveSession()).called(1);

    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();

    expect(find.text('다음 날'), findsOneWidget);

    // 끝내고 나면 진행 중인 판은 더 이상 없다.
    when(
      () => useCase.getActiveSession(),
    ).thenAnswer((_) async => const Ok<TradeSession?>(null));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('청산하고 끝내기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '청산하고 끝내기'));
    await tester.pumpAndSettle();

    expect(find.text('결과 화면'), findsOneWidget);
    // 진행 화면은 결과로 갈아치워졌을 뿐이라 홈은 아직 가려져 있다 —
    // 다시 읽는 것은 홈이 실제로 드러나는 순간이다.
    verifyNever(() => useCase.getActiveSession());

    // 결과에서 뒤로 나오면 홈이 드러나고, 그때 다시 읽는다. 그래서 홈은 새
    // 판을 시작할 수 있는 모습이다 — 끝난 판을 이어하기로 걸어 두지 않는다.
    router.pop();
    await tester.pumpAndSettle();

    verify(() => useCase.getActiveSession()).called(1);
    expect(find.text('새 판 시작'), findsOneWidget);
    expect(find.text('이어하기'), findsNothing);
  });
}
