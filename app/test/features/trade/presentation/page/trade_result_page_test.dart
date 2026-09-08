import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTradeUseCase extends Mock implements TradeUseCase {}

TradeSession _finished({
  double returnPct = 12.34,
  double buyHoldReturnPct = 3,
}) => TradeSession(
  id: 's1',
  userId: 'me',
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

  setUp(() {
    useCase = _MockTradeUseCase();
    getIt.registerFactory<TradeSessionCubit>(() => TradeSessionCubit(useCase));
  });

  tearDown(getIt.reset);

  Future<void> pumpResult(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다.
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TradeResultPage(sessionId: 's1'),
      ),
    );
    await tester.pumpAndSettle();
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
}
