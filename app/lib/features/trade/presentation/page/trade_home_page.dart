import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../core/result/result.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_list_tile.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feed/presentation/widget/feed_list_footer.dart';
import '../../../feed/presentation/widget/feed_load_more_listener.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_session_summary.dart';
import '../../domain/ledger/trade_ledger.dart';
import '../../domain/trade_rules.dart';
import '../cubit/trade_home_cubit.dart';
import '../cubit/trade_home_state.dart';
import '../format/trade_format.dart';

/// 모의투자 탭. 진행 중인 판 하나와 지난 판 목록을 보여준다.
///
/// 진행 중인 판이 있으면 "이어하기"가 맨 위를 차지하고 시작 버튼은 나오지
/// 않는다 — 사용자당 진행 중인 판은 하나뿐이라, 이 자리에서 시작할 수 있는
/// 것처럼 보이면 서버가 거절하는 버튼을 보여주는 셈이 된다.
class TradeHomePage extends StatelessWidget {
  const TradeHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<TradeHomeCubit>()..load(),
    child: const _TradeHomeView(),
  );
}

class _TradeHomeView extends StatelessWidget {
  const _TradeHomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tradeHomeTitle)),
      body: SafeArea(
        child: BlocBuilder<TradeHomeCubit, TradeHomeState>(
          builder: (context, state) => switch (state) {
            TradeHomeLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TradeHomeFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                onAction: () => context.read<TradeHomeCubit>().refresh(),
              ),
            ),
            TradeHomeLoaded() => RefreshIndicator(
              onRefresh: () => context.read<TradeHomeCubit>().refresh(),
              child: FeedLoadMoreListener(
                onLoadMore: () {
                  if (!state.isLoadingMore && state.canLoadMore) {
                    context.read<TradeHomeCubit>().loadMore();
                  }
                },
                child: _TradeHomeList(state: state),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _TradeHomeList extends StatelessWidget {
  const _TradeHomeList({required this.state});

  final TradeHomeLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = state.active;
    final isEmpty = active == null && state.past.isEmpty;

    return ListView(
      // 비어 있어도 스크롤은 살려 둔다 — 당겨서 새로고침이 동작해야 한다.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        if (active != null) _ResumeCard(session: active),
        if (isEmpty) ...[
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
          AppPlaceholder(
            icon: Icons.candlestick_chart_outlined,
            message: l10n.tradeEmptyTitle,
            description: l10n.tradeEmptyDescription,
          ),
        ],
        if (active == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _StartButton(isStarting: state.isStarting),
          ),
        if (state.past.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.tradePastSessions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final summary in state.past) _PastSessionRow(summary: summary),
          FeedListFooter(
            isLoadingMore: state.isLoadingMore,
            canLoadMore: state.canLoadMore,
          ),
        ],
      ],
    );
  }
}

/// 진행 중인 판으로 돌아가는 카드.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.session});

  final TradeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final equity = TradeLedger.equity(
      session.cash,
      session.quantity,
      session.currentClose,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AppListTile(
        title: Text(l10n.tradeResume),
        subtitle: Text(l10n.tradeStepOf(session.step, TradeRules.tradeSteps)),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.tradeEquity,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              TradeFormat.amount(equity, l10n.localeName),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        onTap: () => _openSession(context, session.id),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.isStarting});

  final bool isStarting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child: AppButton.primary(
        label: l10n.tradeStart,
        // 시작은 서버에 판을 만든다. 두 번 눌러 두 판이 생기지 않도록 응답이
        // 올 때까지 잠근다.
        onPressed: isStarting ? null : () => _start(context),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final cubit = context.read<TradeHomeCubit>();
    final result = await cubit.start();
    if (!context.mounted) return;

    switch (result) {
      case Ok(value: final sessionId):
        await _openSession(context, sessionId);
      case Err(:final failure):
        AppSnackBar.show(
          context,
          message: failure.localizedMessage(context),
          type: AppSnackBarType.error,
        );
    }
  }
}

/// 끝난 판 한 줄. 종목 · 기간과 수익률만 보여주고 결과 화면으로 보낸다.
class _PastSessionRow extends StatelessWidget {
  const _PastSessionRow({required this.summary});

  final TradeSessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = summary.result;

    return AppListTile(
      title: Text(
        result == null
            // 목록은 끝난 판만 읽으므로 실제로는 오지 않는 자리다. 결과가 빠진
            // 행이 섞여 와도 목록이 무너지지 않게 날짜만 보여준다.
            ? TradeFormat.dayRange(summary.createdAt, summary.createdAt)
            : '${result.displaySymbol} · '
                  '${TradeFormat.dayRange(result.startDay, result.endDay)}',
      ),
      trailing: result == null
          ? null
          : Text(
              TradeFormat.signedPct(result.returnPct),
              style: theme.textTheme.titleMedium?.copyWith(
                color: _returnColor(theme, result.returnPct),
              ),
            ),
      onTap: () => context.push(Routes.tradeResultPath(summary.id)),
    );
  }

  /// 상승 빨강 · 하락 파랑. 0 은 방향이 없으므로 본문 색 그대로 둔다.
  static Color? _returnColor(ThemeData theme, double returnPct) {
    if (returnPct > 0) return AppColors.candleUp;
    if (returnPct < 0) return AppColors.candleDown;
    return null;
  }
}

/// 판 화면으로 들어갔다가 돌아오면 홈을 다시 읽는다.
///
/// 판 화면에서 매매하거나 판을 끝내고 나온다. 그때 이어하기 카드의 진행도와
/// 지난 판 목록이 방금 한 일을 반영하지 않으면 홈이 옛 화면으로 남는다.
Future<void> _openSession(BuildContext context, String sessionId) async {
  final cubit = context.read<TradeHomeCubit>();
  await context.push(Routes.tradeSessionPath(sessionId));
  if (cubit.isClosed) return;
  await cubit.refresh();
}
