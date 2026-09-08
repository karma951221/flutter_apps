import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/trade_result.dart';
import '../../domain/entity/trade_session.dart';
import '../cubit/trade_session_cubit.dart';
import '../cubit/trade_session_state.dart';
import '../format/trade_format.dart';
import '../widget/trade_candle_chart.dart';

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
          _MetricRow(
            children: [
              _MetricCard(
                label: l10n.tradeReturn,
                value: TradeFormat.signedPct(result.returnPct),
                valueStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: _returnColor(result.returnPct),
                ),
              ),
              _MetricCard(
                label: l10n.tradeBuyHold,
                value: TradeFormat.signedPct(result.buyHoldReturnPct),
              ),
            ],
          ),
          _MetricRow(
            children: [
              _MetricCard(
                label: l10n.tradeMaxDrawdown,
                // 낙폭은 항상 0 이상으로 오지만 읽는 사람에겐 아래로 내려간
                // 폭이다. 부호를 뒤집어 음수로 보여준다.
                value: TradeFormat.signedPct(-result.maxDrawdownPct),
              ),
              _MetricCard(
                label: l10n.tradeCount,
                value: l10n.tradeCountValue(result.tradeCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color? _returnColor(double returnPct) {
    if (returnPct > 0) return AppColors.candleUp;
    if (returnPct < 0) return AppColors.candleDown;
    return null;
  }
}

/// 지표 카드 두 장을 한 줄에 같은 너비 · 같은 높이로 놓는다.
///
/// 높이를 맞추는 이유는 글자 수가 달라 카드가 어긋나면 지표보다 배치가 먼저
/// 눈에 들어오기 때문이다. `stretch` 만으로는 세로가 무한인 목록 안에서
/// 높이를 정할 수 없어 [IntrinsicHeight] 가 함께 있어야 한다.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final child in children) Expanded(child: child)],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: valueStyle ?? theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
