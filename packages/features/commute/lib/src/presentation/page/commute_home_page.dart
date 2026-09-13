import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';
import '../cubit/commute_home_cubit.dart';
import '../cubit/commute_home_state.dart';
import '../widget/direction_toggle.dart';
import '../widget/origin_banner.dart';
import '../widget/transit_route_card.dart';

/// 설정 화면을 여는 콜백은 설정이 닫힐 때 완료되는 Future를 돌려준다.
/// 홈은 그때 다시 검색한다 — 역을 바꾸고 돌아왔는데 이전 결과가 남지 않도록.
typedef OpenSettingsCallback = Future<void> Function();

class CommuteHomePage extends StatelessWidget {
  const CommuteHomePage({required this.onOpenSettings, super.key});

  final OpenSettingsCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CommuteHomeCubit>()..load(),
    child: _CommuteHomeView(onOpenSettings: onOpenSettings),
  );
}

class _CommuteHomeView extends StatelessWidget {
  const _CommuteHomeView({required this.onOpenSettings});

  final OpenSettingsCallback onOpenSettings;

  Future<void> _openSettings(BuildContext context) async {
    final cubit = context.read<CommuteHomeCubit>();
    await onOpenSettings();
    if (!cubit.isClosed) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commuteAppTitle),
        actions: [
          IconButton(
            key: const Key('commute-open-settings'),
            tooltip: l10n.commuteOpenSettingsTooltip,
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<CommuteHomeCubit, CommuteHomeState>(
          builder: (context, state) {
            final direction = switch (state) {
              CommuteHomeInitial(:final direction) ||
              CommuteHomeLoading(:final direction) ||
              CommuteHomeLoaded(:final direction) ||
              CommuteHomeFailure(:final direction) => direction,
            };
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: DirectionToggle(
                    direction: direction,
                    onChanged: context.read<CommuteHomeCubit>().setDirection,
                  ),
                ),
                Expanded(
                  child: switch (state) {
                    CommuteHomeInitial() || CommuteHomeLoading() =>
                      const Center(child: CircularProgressIndicator()),
                    CommuteHomeFailure(:final failure) => Center(
                      child: AppPlaceholder(
                        message:
                            failure.failureCode ==
                                FailureCode.commuteNotConfigured
                            ? l10n.commuteSettingsRequiredTitle
                            : failure.localizedMessage(context),
                        description:
                            failure.failureCode ==
                                FailureCode.commuteNotConfigured
                            ? l10n.commuteSettingsRequiredDescription
                            : null,
                        actionLabel:
                            failure.failureCode ==
                                FailureCode.commuteNotConfigured
                            ? l10n.commuteOpenSettings
                            : l10n.commonRetry,
                        onAction:
                            failure.failureCode ==
                                FailureCode.commuteNotConfigured
                            ? () => _openSettings(context)
                            : context.read<CommuteHomeCubit>().refresh,
                      ),
                    ),
                    CommuteHomeLoaded(:final result) => RefreshIndicator(
                      onRefresh: context.read<CommuteHomeCubit>().refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        children: [
                          OriginBanner(
                            origin: result.origin,
                            direction: direction,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (final route in result.routes) ...[
                            TransitRouteCard(route: route),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
