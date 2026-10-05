import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/tracking/entity/tracking_notice.dart';
import '../../dog/widget/dog_chips.dart';
import '../../walk/widget/route_map.dart';
import '../../walk/widget/walk_stats_row.dart';
import '../cubit/active_walk_cubit.dart';
import '../cubit/active_walk_state.dart';

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
              ActiveWalkTracking(
                :final session,
                :final elapsed,
                :final locationError,
              ) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      // 점이 없을 때 오류가 나면 "찾는 중" 대신 오류를 지도 자리에 둔다.
                      child: locationError != null && session.points.isEmpty
                          ? Center(
                              child: _LocationError(
                                failure: locationError,
                                onRetry: cubit.resumeTracking,
                                onOpenSettings: () =>
                                    cubit.openSettings(locationError),
                              ),
                            )
                          : RouteMap(
                              key: const Key('walk-active-map'),
                              points: [for (final p in session.points) p.point],
                              follow: true,
                              emptyMessage: l10n.walkLocating,
                            ),
                    ),
                    if (locationError != null && session.points.isNotEmpty)
                      _LocationError(
                        failure: locationError,
                        onRetry: cubit.resumeTracking,
                        onOpenSettings: () => cubit.openSettings(locationError),
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
                child: _LocationProblem(
                  key: const Key('walk-active-failure'),
                  failure: failure,
                  description: switch (failure.failureCode) {
                    FailureCode.locationPermissionDenied =>
                      l10n.walkLocationDeniedHint,
                    FailureCode.locationServiceDisabled =>
                      l10n.walkLocationServiceHint,
                    _ => null,
                  },
                  retryKey: const Key('walk-active-retry'),
                  onRetry: cubit.retry,
                  onOpenSettings: () => cubit.openSettings(failure),
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// 위치를 쓸 수 없을 때의 안내. 다시 시도는 늘 두고, 권한 거부 · 서비스 꺼짐이면
/// 그 설정을 여는 버튼을 아래에 더한다 — 권한은 세션당 한 번만 묻기 때문에 거부 뒤
/// 다시 시도만으로는 풀리지 않는다.
class _LocationProblem extends StatelessWidget {
  const _LocationProblem({
    required this.failure,
    required this.retryKey,
    required this.onRetry,
    required this.onOpenSettings,
    this.description,
    super.key,
  });

  final Failure failure;
  final String? description;
  final Key retryKey;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsLabel = switch (failure.failureCode) {
      FailureCode.locationPermissionDenied => l10n.walkOpenSettings,
      FailureCode.locationServiceDisabled => l10n.walkOpenLocationSettings,
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPlaceholder(
          message: failure.localizedMessage(context),
          description: description,
          actionLabel: l10n.commonRetry,
          actionKey: retryKey,
          onAction: onRetry,
        ),
        if (settingsLabel != null)
          AppButton.text(
            key: const Key('walk-active-open-settings'),
            label: settingsLabel,
            onPressed: onOpenSettings,
          ),
      ],
    );
  }
}

/// 추적 중 위치 오류. 기록은 이어지고 있음을 알리고 다시 받기를 권한다.
class _LocationError extends StatelessWidget {
  const _LocationError({
    required this.failure,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => _LocationProblem(
    key: const Key('walk-active-location-error'),
    failure: failure,
    description: AppLocalizations.of(context).walkLocationLostHint,
    retryKey: const Key('walk-active-location-retry'),
    onRetry: onRetry,
    onOpenSettings: onOpenSettings,
  );
}
