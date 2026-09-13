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

class CommuteHomePage extends StatelessWidget {
  const CommuteHomePage({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CommuteHomeCubit>()..load(),
    child: _CommuteHomeView(onOpenSettings: onOpenSettings),
  );
}

class _CommuteHomeView extends StatelessWidget {
  const _CommuteHomeView({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

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
            onPressed: onOpenSettings,
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
                            ? onOpenSettings
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
