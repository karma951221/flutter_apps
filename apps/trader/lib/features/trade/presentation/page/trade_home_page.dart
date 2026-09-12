import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:design_system/design_system.dart';
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

/// 홈 위에 얹을 화면을 여는 방법. 상태를 가진 [_TradeHomeViewState] 만 안다.
typedef _OpenRoute = void Function(GoRouter router, String location);

class _TradeHomeView extends StatefulWidget {
  const _TradeHomeView();

  @override
  State<_TradeHomeView> createState() => _TradeHomeViewState();
}

/// 홈 위에 얹은 화면(판 · 결과)에서 돌아오면 목록을 다시 읽는다.
///
/// 판 화면에서 매매하거나 판을 끝내고 나온다. 그때 이어하기 카드의 진행도와
/// 지난 판 목록이 방금 한 일을 반영하지 않으면 홈이 옛 화면으로 남는다.
///
/// 돌아온 것을 `push` 가 돌려주는 future 로 알지 않는다. 판이 끝나면 진행
/// 화면은 결과 화면으로 **갈아치워지는데**(`pushReplacement`), go_router 는
/// 갈아치운 imperative match 의 completer 를 완료하지 않고 버려서 그 future 가
/// 영영 끝나지 않기 때문이다. 대신 내비게이터에게 직접 듣는다 —
/// [appRouteObserver] 가 위의 화면이 걷히는 순간 [didPopNext] 를 부른다.
class _TradeHomeViewState extends State<_TradeHomeView> with RouteAware {
  /// 지금 홈 위에 얹혀 있는 화면에서 돌아오면 다시 읽어야 하는지.
  ///
  /// 구독하는 것은 홈 셸의 라우트다(이 화면은 탭 본문이다). 그래서 다른 탭이
  /// 얹은 화면(작성 · 댓글 · 채팅방)이 걷혀도 [didPopNext] 가 온다 — 이
  /// 플래그가 그중 "내가 연 화면"만 골라낸다.
  bool _expectRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트 밖에서 그려질 수도 있어(위젯 테스트) null 을 견딘다. 같은
    // 라우트로 다시 부르는 것은 subscribe 가 알아서 무시한다.
    final route = ModalRoute.of<void>(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!_expectRefresh) return;
    _expectRefresh = false;
    context.read<TradeHomeCubit>().refresh();
  }

  /// 홈 위에 화면을 얹는다.
  ///
  /// `await` 하지 않는다 — 돌아온 것은 [didPopNext] 로 안다. [router] 를
  /// 인자로 받는 이유는 [_StartButton] 이 await 를 지난 뒤에, 즉 자기 context
  /// 가 죽었을 수도 있는 자리에서 부르기 때문이다.
  void _open(GoRouter router, String location) {
    _expectRefresh = true;
    router.push(location);
  }

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
              child: AppLoadMoreListener(
                onLoadMore: () {
                  if (!state.isLoadingMore && state.canLoadMore) {
                    context.read<TradeHomeCubit>().loadMore();
                  }
                },
                child: _TradeHomeList(state: state, onOpen: _open),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _TradeHomeList extends StatelessWidget {
  const _TradeHomeList({required this.state, required this.onOpen});

  final TradeHomeLoaded state;
  final _OpenRoute onOpen;

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
        if (active != null) _ResumeCard(session: active, onOpen: onOpen),
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
            child: _StartButton(isStarting: state.isStarting, onOpen: onOpen),
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
          for (final summary in state.past)
            _PastSessionRow(summary: summary, onOpen: onOpen),
          AppListFooter(
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
  const _ResumeCard({required this.session, required this.onOpen});

  final TradeSession session;
  final _OpenRoute onOpen;

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
        onTap: () =>
            onOpen(GoRouter.of(context), Routes.tradeSessionPath(session.id)),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.isStarting, required this.onOpen});

  final bool isStarting;
  final _OpenRoute onOpen;

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

  /// [TradeHomeCubit.start] 는 성공하면 **돌아오기 전에** 목록을 다시 읽고,
  /// 그 시작이 loading 을 emit 한다. 그러면 loaded 트리가 통째로
  /// `CircularProgressIndicator` 로 바뀌면서 이 버튼의 element 가 사라진다 —
  /// 실제 앱에서는 그 사이에 프레임이 그려지므로 `context` 가 죽어 있다.
  /// 이동에 필요한 router 를 await 전에 잡아 두고, 살아 있는지는 화면이 아니라
  /// cubit 으로 판단한다.
  Future<void> _start(BuildContext context) async {
    final router = GoRouter.of(context);
    final cubit = context.read<TradeHomeCubit>();
    final result = await cubit.start();
    if (cubit.isClosed) return;

    switch (result) {
      case Ok(value: final sessionId):
        onOpen(router, Routes.tradeSessionPath(sessionId));
      case Err(:final failure):
        // 실패는 loaded 를 유지하므로 버튼이 그대로 남지만, 사용자가 그 사이
        // 탭을 떠났을 수 있어 확인하고 띄운다.
        if (!context.mounted) return;
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
  const _PastSessionRow({required this.summary, required this.onOpen});

  final TradeSessionSummary summary;
  final _OpenRoute onOpen;

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
                color: TradeFormat.returnColor(result.returnPct),
              ),
            ),
      // 결과 화면에서 더 들어갈 수 있어(공유하기) 돌아오면 목록을 다시
      // 읽는다 — 조회 한 번이면 되는 값싼 보험이다.
      onTap: () =>
          onOpen(GoRouter.of(context), Routes.tradeResultPath(summary.id)),
    );
  }
}
