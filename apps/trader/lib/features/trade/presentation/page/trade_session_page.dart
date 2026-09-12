import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_confirm_dialog.dart';
import '../../../../design_system/widget/app_overflow_menu.dart';
import '../../../../design_system/widget/app_placeholder.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../domain/entity/trade_session.dart';
import '../../domain/entity/trade_side.dart';
import '../../domain/ledger/trade_ledger.dart';
import '../../domain/trade_rules.dart';
import '../cubit/trade_session_cubit.dart';
import '../cubit/trade_session_state.dart';
import '../format/trade_format.dart';
import '../widget/trade_candle_chart.dart';
import '../widget/trade_metric_card.dart';
import '../widget/trade_order_sheet.dart';

/// 판 진행 화면. 하루씩 넘기며 매매한다.
///
/// **종목 · 날짜 · 거래량 · 원가격은 여기 어디에도 나오지 않는다.** 그것이
/// 이 판의 규칙이다 — 무슨 종목의 언제인지 알면 결과를 이미 아는 셈이라
/// 매매가 성립하지 않는다. 화면이 보여주는 가격은 index 59 의 종가를 100 으로
/// 맞춘 정규화 종가이고, x 축은 그 기준일로부터의 거리(`D−59 … D+60`)다.
class TradeSessionPage extends StatelessWidget {
  const TradeSessionPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<TradeSessionCubit>()..load(sessionId),
    child: _TradeSessionView(sessionId: sessionId),
  );
}

/// 더보기 메뉴 항목. 지금은 하나뿐이지만 [AppOverflowMenu] 가 값 타입을
/// 요구하고, 항목이 늘어날 자리이기도 하다.
enum _SessionMenuAction { finishNow }

class _TradeSessionView extends StatefulWidget {
  const _TradeSessionView({required this.sessionId});

  final String sessionId;

  @override
  State<_TradeSessionView> createState() => _TradeSessionViewState();
}

class _TradeSessionViewState extends State<_TradeSessionView> {
  /// 결과 화면으로 이미 넘어갔는지.
  ///
  /// 판이 끝나는 순간은 한 번이지만 loaded 는 그 뒤로도 다시 올 수 있다
  /// (예: 넘어가는 프레임 사이에 도착한 응답). 플래그가 없으면 결과 화면이
  /// 여러 장 쌓인다.
  bool _leftForResult = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<TradeSessionCubit, TradeSessionState>(
      listener: _onStateChanged,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.tradeSessionTitle),
          actions: [
            if (state case TradeSessionLoaded(
              :final session,
              :final isSubmitting,
            )) ...[
              Center(
                child: Text(
                  l10n.tradeStepOf(session.step, TradeRules.tradeSteps),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AppOverflowMenu<_SessionMenuAction>(
                items: [
                  AppOverflowMenuItem(
                    value: _SessionMenuAction.finishNow,
                    label: l10n.tradeFinishNow,
                    icon: Icons.flag_outlined,
                    isDestructive: true,
                  ),
                ],
                // 이미 날아간 요청이 있으면 잠근다. 청산은 되돌릴 수 없어서,
                // 주문과 겹쳐 들어가는 경로를 열어 둘 이유가 없다.
                enabled: !isSubmitting && session.canAdvance,
                onSelected: (_) => _finish(),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: switch (state) {
            TradeSessionLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TradeSessionFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                onAction: () =>
                    context.read<TradeSessionCubit>().load(widget.sessionId),
              ),
            ),
            TradeSessionLoaded(:final session, :final isSubmitting) =>
              _SessionBody(
                session: session,
                isSubmitting: isSubmitting,
                onBuy: () => _order(TradeSide.buy, session),
                onSell: () => _order(TradeSide.sell, session),
                onNextDay: _advance,
              ),
          },
        ),
      ),
    );
  }

  /// 판이 끝나면 결과로 갈아탄다.
  ///
  /// 끝난 판의 진행 화면은 돌아갈 곳이 아니라 스택에 남기지 않는다 —
  /// `pushReplacement` 가 이 자리를 결과 화면으로 바꾼다. 걷어 낸 뒤 다시
  /// 얹는(`pop` + `push`) 방법도 있지만 두 전환이 한 프레임에 겹쳐 결과
  /// 화면이 두 번 그려지는 것처럼 보인다.
  ///
  /// 홈은 이 push 가 끝나기를 기다리지 않는다 — go_router 는 갈아치운
  /// imperative match 의 completer 를 버려서 그 future 가 영영 끝나지 않는다.
  /// 대신 홈이 `RouteObserver` 로 "위에 얹힌 화면이 걷혔다"를 듣고 다시 읽는다.
  void _onStateChanged(BuildContext context, TradeSessionState state) {
    if (_leftForResult) return;
    if (state case TradeSessionLoaded(:final session) when session.isFinished) {
      _leftForResult = true;
      final router = GoRouter.of(context);
      router.pushReplacement(Routes.tradeResultPath(widget.sessionId));
    }
  }

  Future<void> _order(TradeSide side, TradeSession session) async {
    final cubit = context.read<TradeSessionCubit>();
    final placedMessage = AppLocalizations.of(context).tradeOrderPlaced;
    final quantity = await TradeOrderSheet.show(
      context,
      side: side,
      session: session,
    );
    if (quantity == null || !mounted) return;

    _report(
      await cubit.placeOrder(side: side, quantity: quantity),
      placedMessage,
    );
  }

  Future<void> _advance() async {
    // 성공 스낵바는 없다. 하루가 넘어간 것은 차트와 진행도가 이미 말한다.
    _report(await context.read<TradeSessionCubit>().advance(), null);
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.tradeFinishConfirmTitle,
      content: l10n.tradeFinishConfirmMessage,
      confirmLabel: l10n.tradeFinishNow,
    );
    if (!confirmed || !mounted) return;

    _report(await context.read<TradeSessionCubit>().finish(), null);
  }

  /// 판을 바꾸는 호출의 결과를 스낵바로 알린다.
  ///
  /// 성공한 뒤 판이 끝났으면 [_onStateChanged] 가 이미 결과 화면으로 넘겼고
  /// 이 위젯은 사라져 있다 — 그래서 [mounted] 를 먼저 본다.
  void _report(Result<TradeSession> result, String? successMessage) {
    if (!mounted) return;
    switch (result) {
      case Ok():
        if (successMessage != null) {
          AppSnackBar.show(
            context,
            message: successMessage,
            type: AppSnackBarType.success,
          );
        }
      case Err(:final failure):
        AppSnackBar.show(
          context,
          message: failure.localizedMessage(context),
          type: AppSnackBarType.error,
        );
    }
  }
}

class _SessionBody extends StatelessWidget {
  const _SessionBody({
    required this.session,
    required this.isSubmitting,
    required this.onBuy,
    required this.onSell,
    required this.onNextDay,
  });

  final TradeSession session;
  final bool isSubmitting;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // 버튼은 늘 손 닿는 자리에 있어야 한다. 차트와 지표만 스크롤한다.
      Expanded(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            // 진행 중이라 종료선(endIndex)이 없다.
            TradeCandleChart(candles: session.candles, orders: session.orders),
            _CurrentPrice(session: session),
            _Metrics(session: session),
          ],
        ),
      ),
      _Actions(
        session: session,
        isSubmitting: isSubmitting,
        onBuy: onBuy,
        onSell: onSell,
        onNextDay: onNextDay,
      ),
    ],
  );
}

/// 현재 봉의 정규화 종가. 단위가 없다 — 기준일을 100 으로 맞춘 지수다.
class _CurrentPrice extends StatelessWidget {
  const _CurrentPrice({required this.session});

  final TradeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.tradeCurrentPrice,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            TradeFormat.amount(session.currentClose, l10n.localeName),
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

/// 현금 · 보유 수량 · 평가액 · 현재 수익률 네 칸.
class _Metrics extends StatelessWidget {
  const _Metrics({required this.session});

  final TradeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final equity = TradeLedger.equity(
      session.cash,
      session.quantity,
      session.currentClose,
    );
    final returnPct = TradeLedger.returnPct(equity, TradeRules.initialCash);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          TradeMetricRow(
            children: [
              TradeMetricCard(
                label: l10n.tradeCash,
                value: TradeFormat.amount(session.cash, locale),
              ),
              TradeMetricCard(
                label: l10n.tradeQuantity,
                value: TradeFormat.quantity(session.quantity),
              ),
            ],
          ),
          TradeMetricRow(
            children: [
              TradeMetricCard(
                label: l10n.tradeEquity,
                value: TradeFormat.amount(equity, locale),
              ),
              TradeMetricCard(
                label: l10n.tradeCurrentReturn,
                value: TradeFormat.signedPct(returnPct),
                valueStyle: theme.textTheme.titleLarge?.copyWith(
                  color: TradeFormat.returnColor(returnPct),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 매수 · 매도 한 줄, 그 아래 다음 날.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.session,
    required this.isSubmitting,
    required this.onBuy,
    required this.onSell,
    required this.onNextDay,
  });

  final TradeSession session;
  final bool isSubmitting;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 응답이 오는 동안은 셋 다 잠근다 — cubit 이 두 번째 요청을 거절하므로,
    // 눌리는 것처럼 보이는 버튼을 남겨 두면 아무 일도 안 일어나는 것처럼
    // 보인다.
    final isLocked = isSubmitting || !session.canAdvance;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: l10n.tradeBuy,
                  onPressed: isLocked ? null : onBuy,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton.secondary(
                  label: l10n.tradeSell,
                  // 없는 것을 팔 수는 없다. 롱만 되는 판이라 공매도도 없다.
                  onPressed: isLocked || session.quantity <= 0 ? null : onSell,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: l10n.tradeNextDay,
              onPressed: isLocked ? null : onNextDay,
            ),
          ),
        ],
      ),
    );
  }
}
