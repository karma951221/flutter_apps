import 'dart:async';

import 'package:daylog/app/router/route_observer.dart';
import 'package:daylog/app/router/routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:daylog/features/trade/domain/entity/trade_candle.dart';
import 'package:daylog/features/trade/domain/entity/trade_result.dart';
import 'package:daylog/features/trade/domain/entity/trade_session.dart';
import 'package:daylog/features/trade/domain/entity/trade_session_summary.dart';
import 'package:daylog/features/trade/domain/trade_rules.dart';
import 'package:daylog/features/trade/domain/usecase/trade_use_case.dart';
import 'package:daylog/features/trade/presentation/cubit/trade_home_cubit.dart';
import 'package:daylog/features/trade/presentation/page/trade_home_page.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeUseCase extends Mock implements TradeUseCase {}

TradeSession _active({int step = 3}) => TradeSession(
  id: 'active-1',
  userId: 'me',
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

TradeSessionSummary _summary({double returnPct = 12.34}) => TradeSessionSummary(
  id: 'past-1',
  createdAt: DateTime.utc(2026, 9, 1, 9),
  finishedAt: DateTime.utc(2026, 9, 1, 10),
  result: TradeResult(
    symbol: 'BTCUSDT',
    startDay: DateTime.utc(2021, 11),
    endDay: DateTime.utc(2022, 1, 29),
    endIndex: 119,
    finalEquity: 11234,
    returnPct: returnPct,
    buyHoldReturnPct: 3,
    maxDrawdownPct: 8,
    tradeCount: 4,
  ),
);

void main() {
  late _MockTradeUseCase useCase;

  setUp(() {
    useCase = _MockTradeUseCase();
    getIt.registerFactory<TradeHomeCubit>(() => TradeHomeCubit(useCase));
  });

  tearDown(getIt.reset);

  void stubLoad({
    TradeSession? active,
    List<TradeSessionSummary> past = const [],
  }) {
    when(
      () => useCase.getActiveSession(),
    ).thenAnswer((_) async => Ok<TradeSession?>(active));
    when(
      () => useCase.getPastSessions(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage<TradeSessionSummary>(items: past)));
  }

  /// 눌러서 넘어가는 곳(판 화면 · 결과 화면)은 이 태스크의 범위가 아니라
  /// 표시만 하는 라우트로 대신한다. 마지막으로 들어간 경로를 돌려준다.
  ///
  /// 홈이 "얹은 화면에서 돌아왔다"를 [appRouteObserver] 로 듣기 때문에
  /// 테스트 라우터도 실제 앱과 같이 그 observer 를 단다.
  Future<String? Function()> pumpHome(WidgetTester tester) async {
    String? visited;
    final router = GoRouter(
      observers: [appRouteObserver],
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => const TradeHomePage()),
        GoRoute(
          path: Routes.tradeSession,
          builder: (_, state) {
            visited = state.matchedLocation;
            return const Scaffold(body: Text('판 화면'));
          },
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

    return () => visited;
  }

  testWidgets('진행 중인 판이 있으면 이어하기 카드가 맨 위에 온다', (tester) async {
    stubLoad(active: _active());

    await pumpHome(tester);

    expect(find.text('모의투자'), findsOneWidget);
    expect(find.text('이어하기'), findsOneWidget);
    expect(find.text('3 / 60'), findsOneWidget);
    expect(find.text('평가액'), findsOneWidget);
    expect(find.text('10,000.00'), findsOneWidget);
    // 진행 중인 판은 하나뿐이라 시작 버튼은 나오지 않는다.
    expect(find.text('새 판 시작'), findsNothing);
  });

  testWidgets('이어하기를 누르면 그 판으로 들어가고 돌아오면 다시 읽는다', (tester) async {
    stubLoad(active: _active());

    final visited = await pumpHome(tester);
    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();

    expect(visited(), '/trade/active-1');

    // 돌아오면 홈이 옛 화면으로 남지 않는다 — push future 가 아니라
    // RouteObserver 가 그 순간을 알린다. 다시 읽는 조회를 열어 둔 채 프레임을
    // 그려, 그 사이 화면이 loading 으로 바뀌어도 갱신이 끝까지 가는지 함께
    // 본다.
    final reload = Completer<Result<TradeSession?>>();
    when(() => useCase.getActiveSession()).thenAnswer((_) => reload.future);
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    reload.complete(Ok<TradeSession?>(_active(step: 4)));
    await tester.pumpAndSettle();

    expect(find.text('4 / 60'), findsOneWidget);
  });

  testWidgets('진행 중인 판이 없으면 시작 버튼을 보여준다', (tester) async {
    stubLoad(past: [_summary()]);

    await pumpHome(tester);

    expect(find.text('새 판 시작'), findsOneWidget);
    expect(find.text('이어하기'), findsNothing);
  });

  testWidgets('아무 판도 없으면 빈 안내와 시작 버튼을 함께 보여준다', (tester) async {
    stubLoad();

    await pumpHome(tester);

    expect(find.text('아직 해본 판이 없습니다'), findsOneWidget);
    expect(find.text('과거 시세를 하루씩 넘기며 매매해 보세요'), findsOneWidget);
    expect(find.text('새 판 시작'), findsOneWidget);
    expect(find.text('지난 판'), findsNothing);
  });

  testWidgets('지난 판 행은 종목 · 기간과 수익률을 보여주고 결과로 보낸다', (tester) async {
    stubLoad(past: [_summary()]);

    final visited = await pumpHome(tester);

    expect(find.text('지난 판'), findsOneWidget);
    // USDT 접미는 떼고 보여준다.
    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
    expect(find.text('+12.34%'), findsOneWidget);

    await tester.tap(find.text('BTC · 2021-11-01 ~ 2022-01-29'));
    await tester.pumpAndSettle();

    expect(visited(), '/trade/past-1/result');
  });

  testWidgets('내린 판은 빼기 부호로 찍는다', (tester) async {
    stubLoad(past: [_summary(returnPct: -5.1)]);

    await pumpHome(tester);

    expect(find.text('−5.10%'), findsOneWidget);
  });

  testWidgets('시작이 실패하면 스낵바로 알리고 화면에 머문다', (tester) async {
    stubLoad();
    when(useCase.startSession).thenAnswer(
      (_) async => const Err(Failure.server(message: '판을 만들지 못했습니다')),
    );

    final visited = await pumpHome(tester);
    await tester.tap(find.text('새 판 시작'));
    await tester.pumpAndSettle();

    expect(find.text('판을 만들지 못했습니다'), findsOneWidget);
    expect(visited(), isNull);
    expect(find.text('새 판 시작'), findsOneWidget);
  });

  testWidgets('시작에 성공하면 목록을 다시 읽는 사이 화면이 바뀌어도 판으로 들어간다', (tester) async {
    stubLoad();
    when(useCase.startSession).thenAnswer((_) async => const Ok('new-1'));

    final visited = await pumpHome(tester);

    // start 는 성공하면 돌아오기 전에 목록을 다시 읽고, 그 조회가 loading 을
    // emit 해 loaded 트리를 통째로 갈아치운다. 조회를 열어 둔 채 프레임을
    // 그려서 실제 앱과 같은 상황(시작 버튼의 element 가 사라진 상태)을
    // 만든다 — 이동이 여기서 끊기면 사용자는 새 판에 들어가지 못한다.
    final reload = Completer<Result<TradeSession?>>();
    when(() => useCase.getActiveSession()).thenAnswer((_) => reload.future);

    await tester.tap(find.text('새 판 시작'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('새 판 시작'), findsNothing);

    reload.complete(const Ok<TradeSession?>(null));
    await tester.pumpAndSettle();

    expect(visited(), '/trade/new-1');
  });

  testWidgets('조회가 실패하면 다시 시도를 보여준다', (tester) async {
    when(
      () => useCase.getActiveSession(),
    ).thenAnswer((_) async => const Err(Failure.network()));
    when(
      () => useCase.getPastSessions(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async => const Ok(CursorPage<TradeSessionSummary>(items: [])),
    );

    await pumpHome(tester);

    expect(find.text('다시 시도'), findsOneWidget);

    stubLoad(past: [_summary()]);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('BTC · 2021-11-01 ~ 2022-01-29'), findsOneWidget);
  });
}
