import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/tracking_notice.dart';
import '../cubit/active_walk_cubit.dart';
import '../cubit/active_walk_state.dart';
import '../widget/dog_chips.dart';
import '../widget/route_map.dart';
import '../widget/walk_stats_row.dart';

/// 산책 진행 화면. 반려견 선택 → 추적(지도 · 시간 · 거리) → 종료.
///
/// 라우팅은 모른다 — 종료되면 [onStopped], 반려견이 없으면 [onOpenDogs].
class ActiveWalkPage extends StatelessWidget {
  const ActiveWalkPage({
    required this.onStopped,
    required this.onOpenDogs,
    super.key,
  });

  final VoidCallback onStopped;
  final VoidCallback onOpenDogs;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ActiveWalkCubit>()..load(),
    child: _ActiveWalkView(onStopped: onStopped, onOpenDogs: onOpenDogs),
  );
}

class _ActiveWalkView extends StatelessWidget {
  const _ActiveWalkView({required this.onStopped, required this.onOpenDogs});

  final VoidCallback onStopped;
  final VoidCallback onOpenDogs;

  Future<void> _confirmStop(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ActiveWalkCubit>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkStopConfirmTitle,
      content: l10n.walkStopConfirmMessage,
      confirmLabel: l10n.walkStop,
      isDestructive: false,
    );
    if (confirmed) await cubit.stop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ActiveWalkCubit>();

    return BlocListener<ActiveWalkCubit, ActiveWalkState>(
      listenWhen: (previous, current) =>
          previous is! ActiveWalkStopped && current is ActiveWalkStopped,
      listener: (_, _) => onStopped(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.walkActiveTitle)),
        body: SafeArea(
          child: BlocBuilder<ActiveWalkCubit, ActiveWalkState>(
            builder: (context, state) => switch (state) {
              ActiveWalkLoading() || ActiveWalkStarting() => const Center(
                child: CircularProgressIndicator(),
              ),
              // 곧 저장 화면으로 넘어간다. 끝없는 애니메이션을 남기지 않는다.
              ActiveWalkStopped() => const SizedBox.shrink(),
              ActiveWalkSelectingDogs(:final dogs) when dogs.isEmpty => Center(
                child: AppPlaceholder(
                  icon: Icons.pets_outlined,
                  message: l10n.walkActiveNoDogsTitle,
                  description: l10n.walkActiveNoDogsMessage,
                  actionLabel: l10n.walkOpenDogsAction,
                  onAction: onOpenDogs,
                ),
              ),
              ActiveWalkSelectingDogs(:final dogs, :final selectedIds) =>
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.walkSelectDogs,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DogChips(
                        dogs: dogs,
                        selectedIds: selectedIds,
                        onToggle: cubit.toggleDog,
                        photoFile: cubit.photoFile,
                      ),
                      const Spacer(),
                      AppButton.primary(
                        key: const Key('walk-active-start-button'),
                        label: l10n.walkStart,
                        onPressed: selectedIds.isEmpty
                            ? null
                            : () => cubit.start(
                                TrackingNotice(
                                  title: l10n.walkTrackingNotificationTitle,
                                  text: l10n.walkTrackingNotificationText,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ActiveWalkTracking(:final session, :final elapsed) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RouteMap(
                      key: const Key('walk-active-map'),
                      points: [for (final p in session.points) p.point],
                      follow: true,
                      emptyMessage: l10n.walkLocating,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WalkStatsRow(
                          distanceMeters: session.distanceMeters,
                          elapsed: elapsed,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton.primary(
                          key: const Key('walk-active-stop-button'),
                          label: l10n.walkStop,
                          onPressed: () => _confirmStop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ActiveWalkFailure(:final failure) => Center(
                child: AppPlaceholder(
                  key: const Key('walk-active-failure'),
                  message: failure.localizedMessage(context),
                  description:
                      failure.failureCode ==
                          FailureCode.locationPermissionDenied
                      ? l10n.walkLocationDeniedHint
                      : null,
                  actionLabel: l10n.commonRetry,
                  actionKey: const Key('walk-active-retry'),
                  onAction: cubit.retry,
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}
