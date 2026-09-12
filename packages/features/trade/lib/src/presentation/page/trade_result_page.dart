import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/feature_auth.dart';
import '../../domain/entity/trade_result.dart';
import '../../domain/entity/trade_result_summary.dart';
import '../../domain/entity/trade_session.dart';
import '../cubit/trade_session_cubit.dart';
import '../cubit/trade_session_state.dart';
import '../format/trade_format.dart';
import '../widget/trade_candle_chart.dart';
import '../widget/trade_metric_card.dart';

/// 끝난 판의 결과.
///
/// 로그인 여부와 무관하게 열린다 — 공유된 링크를 게스트가 눌러도 같은 화면을
/// 본다(`Routes.openRoutes`). 종목·기간·원가격은 판이 끝난 뒤에만 공개되므로
/// 여기서 처음으로 "무슨 종목의 언제였는지"가 드러난다.
class TradeResultPage extends StatelessWidget {
  const TradeResultPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<TradeSessionCubit>()..load(sessionId),
    child: _TradeResultView(sessionId: sessionId),
  );
}

class _TradeResultView extends StatelessWidget {
  const _TradeResultView({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tradeResultTitle)),
      body: SafeArea(
        child: BlocBuilder<TradeSessionCubit, TradeSessionState>(
          builder: (context, state) => switch (state) {
            TradeSessionLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TradeSessionFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                onAction: () =>
                    context.read<TradeSessionCubit>().load(sessionId),
              ),
            ),
            // 아직 진행 중인 판에는 결과가 없다. 지표를 0 으로 채워 보여주는
            // 대신 아직 볼 게 없다고 말한다.
            TradeSessionLoaded(:final session)
                when !session.isFinished || session.result == null =>
              Center(child: AppPlaceholder(message: l10n.tradeResultNotReady)),
            TradeSessionLoaded(:final session) => _ResultBody(session: session),
          },
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.session});

  final TradeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final result = session.result!;
    final diff = TradeFormat.pct(
      (result.returnPct - result.buyHoldReturnPct).abs(),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '${result.displaySymbol} · '
            '${TradeFormat.dayRange(result.startDay, result.endDay)}',
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _MetricGrid(result: result),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            result.beatBuyHold
                ? l10n.tradeBeatBuyHold(diff)
                : l10n.tradeLostToBuyHold(diff),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        // 공유는 내 판에서만. 남의 결과나 게스트가 보는 화면에는 아예 그리지
        // 않는다 — 눌러도 남의 판을 올릴 수 없다(RLS 가 막는다).
        if (_isMine(context)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppButton.primary(
              label: l10n.tradeShare,
              onPressed: () => _share(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // 판 전체를 한 화면에 놓고 본다. 어디서 사고 팔았는지가 결과 숫자보다
        // 더 많은 것을 말해 준다.
        TradeCandleChart(
          candles: session.candles,
          orders: session.orders,
          endIndex: result.endIndex,
        ),
      ],
    );
  }

  bool _isMine(BuildContext context) =>
      switch (context.watch<AuthBloc>().state) {
        AuthAuthenticated(:final user) => user.id == session.userId,
        _ => false,
      };

  /// 작성 화면으로 결과 요약을 들려 보낸다. 돌아온 뒤에 할 일은 없다 — 성공
  /// 스낵바도, 목록 갱신도 작성 화면과 피드의 몫이다.
  void _share(BuildContext context) {
    final result = session.result!;
    context.push(
      Routes.postCompose,
      // TradeResultSummary 자체가 아니라 JSON 호환 Map 을 넘긴다 — go_router 가
      // extra 에 codec 없는 클래스를 만나면 상태 복원 시도에서 경고를 낸다.
      extra: TradeResultSummary(
        sessionId: session.id,
        symbol: result.symbol,
        startDay: result.startDay,
        endDay: result.endDay,
        returnPct: result.returnPct,
        buyHoldReturnPct: result.buyHoldReturnPct,
        maxDrawdownPct: result.maxDrawdownPct,
        tradeCount: result.tradeCount,
      ).toMap(),
    );
  }
}

/// 지표 네 개를 2×2 로 놓는다.
///
/// `GridView` 대신 줄 두 개다 — 칸 수가 넷으로 고정이라 스크롤도 개수 계산도
/// 필요 없고, 수익률만 큰 글씨라 칸 높이를 하나로 못박을 수도 없다.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.result});

  final TradeResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          TradeMetricRow(
            children: [
              TradeMetricCard(
                label: l10n.tradeReturn,
                value: TradeFormat.signedPct(result.returnPct),
                valueStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: TradeFormat.returnColor(result.returnPct),
                ),
              ),
              TradeMetricCard(
                label: l10n.tradeBuyHold,
                value: TradeFormat.signedPct(result.buyHoldReturnPct),
              ),
            ],
          ),
          TradeMetricRow(
            children: [
              TradeMetricCard(
                label: l10n.tradeMaxDrawdown,
                // 낙폭은 항상 0 이상으로 오지만 읽는 사람에겐 아래로 내려간
                // 폭이다. 부호를 뒤집어 음수로 보여준다.
                value: TradeFormat.signedPct(-result.maxDrawdownPct),
              ),
              TradeMetricCard(
                label: l10n.tradeCount,
                value: l10n.tradeCountValue(result.tradeCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
