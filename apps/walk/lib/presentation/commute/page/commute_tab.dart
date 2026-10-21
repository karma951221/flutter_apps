import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/commute_failure.dart';
import '../../../domain/commute/commute_policy.dart';
import '../../../domain/commute/entity/commute_direction.dart';
import '../../../domain/commute/entity/commute_result.dart';
import '../../../domain/commute/entity/place.dart';
import '../cubit/commute_cubit.dart';
import '../cubit/commute_state.dart';
import '../widget/arrival_card.dart';
import '../widget/place_row.dart';
import '../widget/place_setup_sheet.dart';
import '../widget/route_options_sheet.dart';
import '../widget/route_summary.dart';
import '../widget/verdict_banner.dart';

/// 통근 탭. cubit 은 셸이 아니라 이 탭이 소유한다.
class CommuteTab extends StatelessWidget {
  const CommuteTab({required this.active, super.key});

  /// 탭이 보이는 중인지 — 보일 때만 낡음 표시를 주기적으로 다시 그린다.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommuteCubit(getIt(), getIt(), getIt(), getIt<Clock>()),
      child: Builder(
        builder: (context) => CommuteView(
          active: active,
          onEditPlace: (kind) => showPlaceSetupSheet(context, kind),
          onShowRoutes: () {
            final status = context.read<CommuteCubit>().state.status;
            if (status is CommuteLoaded) {
              showRouteOptionsSheet(context, status.result);
            }
          },
        ),
      ),
    );
  }
}

/// 통근 탭 본문. 위에서 [CommuteCubit] 을 받는다.
class CommuteView extends StatefulWidget {
  const CommuteView({
    required this.active,
    this.onEditPlace,
    this.onShowRoutes,
    super.key,
  });

  final bool active;

  /// 장소 줄에서 집 · 회사를 눌렀을 때.
  final ValueChanged<PlaceKind>? onEditPlace;

  /// "다른 경로 n개"를 눌렀을 때.
  final VoidCallback? onShowRoutes;

  @override
  State<CommuteView> createState() => _CommuteViewState();
}

class _CommuteViewState extends State<CommuteView> {
  /// 낡음 표시를 다시 그리는 주기. 네트워크 호출이 아니다.
  static const _refreshEvery = Duration(seconds: 30);

  /// 오래된 결과를 흐리게 그리는 불투명도.
  static const _staleOpacity = 0.4;

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(CommuteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = widget.active
        ? Timer.periodic(_refreshEvery, (_) {
            if (mounted) setState(() {});
          })
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkShellTabCommute)),
      body: BlocBuilder<CommuteCubit, CommuteState>(
        builder: (context, state) {
          final cubit = context.read<CommuteCubit>();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              SegmentedButton<CommuteDirection>(
                segments: [
                  ButtonSegment(
                    value: CommuteDirection.toWork,
                    label: Text(l10n.walkCommuteToWork),
                  ),
                  ButtonSegment(
                    value: CommuteDirection.toHome,
                    label: Text(l10n.walkCommuteToHome),
                  ),
                ],
                selected: {state.direction},
                onSelectionChanged: (s) => cubit.setDirection(s.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              PlaceRow(
                direction: state.direction,
                home: state.home,
                work: state.work,
                onEditPlace: widget.onEditPlace,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.primary(
                label: l10n.walkCommuteQuery,
                isLoading: state.status is CommuteLoading,
                onPressed: cubit.query,
              ),
              const SizedBox(height: AppSpacing.lg),
              ..._body(context, state),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, CommuteState state) {
    final l10n = AppLocalizations.of(context);
    return switch (state.status) {
      CommuteIdle() when state.home == null || state.work == null => [
        AppPlaceholder(
          icon: Icons.place_outlined,
          message: l10n.walkCommuteMissingPlaces,
        ),
      ],
      CommuteIdle() || CommuteLoading() => const [],
      CommuteLoaded(:final result) => [_result(context, result)],
      CommuteFailed(:final failure) => [
        AppPlaceholder(
          icon: Icons.error_outline,
          message: _failureText(l10n, failure),
        ),
      ],
    };
  }

  Widget _result(BuildContext context, CommuteResult result) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stale = isStale(result.queriedAt, getIt<Clock>().now());
    final first = result.route.firstSubway;
    final queried = l10n.walkCommuteQueriedAt(
      RouteSummary.clockTime(result.queriedAt),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: stale ? _staleOpacity : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VerdictBanner(verdict: result.verdict),
              const SizedBox(height: AppSpacing.md),
              if (first != null) ...[
                ArrivalCard(
                  leg: first,
                  arrivals: result.arrivals,
                  realtime: result.realtime,
                  walkMinutes: result.route.walkToStationMinutes,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              RouteSummary(result: result, onShowRoutes: widget.onShowRoutes),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          queried,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (stale)
          Text(
            l10n.walkCommuteStale,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  static String _failureText(AppLocalizations l10n, CommuteFailure failure) =>
      switch (failure) {
        CommuteMissingPlaces() => l10n.walkCommuteMissingPlaces,
        CommuteMissingKey() => l10n.walkCommuteMissingKey,
        CommuteNetwork() => l10n.walkCommuteNetwork,
        CommuteNoRoute() => l10n.walkCommuteNoRoute,
        CommuteServer(:final message) => l10n.walkCommuteServer(message),
      };
}
