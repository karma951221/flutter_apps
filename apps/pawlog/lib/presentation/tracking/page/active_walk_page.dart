import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/tracking/entity/tracking_notice.dart';
import '../../../domain/walk/entity/geo_point.dart';
import '../../common/widget/pawlog_primary_button.dart';
import '../../dog/widget/dog_chips.dart';
import '../../theme/pawlog_theme.dart';
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
      child: BlocBuilder<ActiveWalkCubit, ActiveWalkState>(
        builder: (context, state) => Scaffold(
          // 시작 전(반려견 고르기 · 시작 중 · 실패)은 '산책 준비', 추적부터 '산책 중'(QA P1).
          appBar: AppBar(
            title: Text(switch (state) {
              ActiveWalkLoading() => '',
              ActiveWalkTracking() ||
              ActiveWalkStopped() => l10n.walkActiveTitle,
              _ => l10n.walkReadyTitle,
            }),
          ),
          body: SafeArea(
            child: switch (state) {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(PawlogSize.gutter),
                        children: [
                          Text(
                            l10n.walkSelectDogs,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: PawlogSpacing.md),
                          DogChips(
                            dogs: dogs,
                            selectedIds: selectedIds,
                            onToggle: cubit.toggleDog,
                            photoFile: cubit.photoFile,
                          ),
                        ],
                      ),
                    ),
                    PawlogBottomAction(
                      child: PawlogPrimaryButton(
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
                    ),
                  ],
                ),
              ActiveWalkTracking(
                :final session,
                :final elapsed,
                :final locationError,
              ) =>
                _TrackingView(
                  points: [for (final p in session.points) p.point],
                  distanceMeters: session.distanceMeters,
                  elapsed: elapsed,
                  isPaused: session.isPaused,
                  locationError: locationError,
                  onRetry: cubit.resumeTracking,
                  onOpenSettings: (failure) => cubit.openSettings(failure),
                  onTogglePause: session.isPaused ? cubit.unpause : cubit.pause,
                  onStop: () => _confirmStop(context),
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

/// 추적 중 — 지도 위로 20 둥근 시트가 올라와 거리 · 시간 두 숫자만 44 로 보인다.
///
/// 점이 생기기 전(찾는 중 · 오류)에는 지도 대신 안내가 그 자리를 차지하고, 시트는 아래에 붙는다.
class _TrackingView extends StatelessWidget {
  const _TrackingView({
    required this.points,
    required this.distanceMeters,
    required this.elapsed,
    required this.isPaused,
    required this.locationError,
    required this.onRetry,
    required this.onOpenSettings,
    required this.onTogglePause,
    required this.onStop,
  });

  final List<GeoPoint> points;
  final double distanceMeters;
  final Duration elapsed;
  final bool isPaused;
  final Failure? locationError;
  final VoidCallback onRetry;
  final ValueChanged<Failure> onOpenSettings;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = locationError;

    final sheet = _TrackingSheet(
      distanceMeters: distanceMeters,
      elapsed: elapsed,
      isPaused: isPaused,
      onTogglePause: onTogglePause,
      onStop: onStop,
      // 지도가 있으면 오류는 시트 안에 — 기록은 이어지고 있다.
      error: error != null && points.isNotEmpty
          ? _LocationError(
              failure: error,
              onRetry: onRetry,
              onOpenSettings: () => onOpenSettings(error),
            )
          : null,
    );

    if (points.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            // 점이 없을 때 오류가 나면 "찾는 중" 대신 오류를 지도 자리에 둔다.
            child: error != null
                ? Center(
                    child: _LocationError(
                      failure: error,
                      onRetry: onRetry,
                      onOpenSettings: () => onOpenSettings(error),
                    ),
                  )
                : RouteMap(
                    key: const Key('walk-active-map'),
                    points: points,
                    follow: true,
                    // 멈춘 동안에는 위치를 찾지 않는다 — 찾는 중이라고 하면 틀린 말이다.
                    emptyMessage: isPaused
                        ? l10n.walkPausedLabel
                        : l10n.walkLocating,
                  ),
          ),
          sheet,
        ],
      );
    }

    // 지도는 시트 위 끝에서 둥근 모서리만큼만 시트 밑으로 들어간다. 그 아래로 깔면
    // 출처 표시(OSM 필수)와 경로 일부가 시트에 가린다.
    return CustomMultiChildLayout(
      delegate: _MapUnderSheetLayout(),
      children: [
        LayoutId(
          id: _MapUnderSheetLayout.map,
          child: RouteMap(
            key: const Key('walk-active-map'),
            points: points,
            follow: true,
            emptyMessage: l10n.walkLocating,
            bottomInset: PawlogRadius.sheet,
          ),
        ),
        LayoutId(id: _MapUnderSheetLayout.sheet, child: sheet),
      ],
    );
  }
}

/// 시트를 아래에 붙이고, 지도는 위에서부터 시트 위 끝 + 둥근 모서리([PawlogRadius.sheet])까지.
class _MapUnderSheetLayout extends MultiChildLayoutDelegate {
  static const map = 'map';
  static const sheet = 'sheet';

  @override
  void performLayout(Size size) {
    final sheetSize = layoutChild(
      sheet,
      BoxConstraints.tightFor(
        width: size.width,
      ).copyWith(maxHeight: size.height),
    );
    final sheetTop = size.height - sheetSize.height;
    positionChild(sheet, Offset(0, sheetTop));
    final mapHeight = (sheetTop + PawlogRadius.sheet).clamp(0.0, size.height);
    layoutChild(map, BoxConstraints.tight(Size(size.width, mapHeight)));
    positionChild(map, Offset.zero);
  }

  @override
  bool shouldRelayout(_MapUnderSheetLayout oldDelegate) => false;
}

class _TrackingSheet extends StatelessWidget {
  const _TrackingSheet({
    required this.distanceMeters,
    required this.elapsed,
    required this.isPaused,
    required this.onTogglePause,
    required this.onStop,
    this.error,
  });

  final double distanceMeters;
  final Duration elapsed;
  final bool isPaused;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = PawlogColors.of(context);

    return DecoratedBox(
      key: const Key('walk-active-sheet'),
      decoration: BoxDecoration(
        color: colors.sheet,
        borderRadius: PawlogRadius.sheetTop,
        boxShadow: PawlogShadows.sheet(colors.shadow),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: PawlogSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?error,
            if (isPaused)
              Padding(
                padding: const EdgeInsets.only(
                  left: PawlogSize.gutter,
                  right: PawlogSize.gutter,
                  bottom: PawlogSpacing.sm,
                ),
                child: Text(
                  l10n.walkPausedLabel,
                  key: const Key('walk-active-paused-label'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colors.textMuted),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PawlogSize.gutter,
              ),
              child: WalkStatsRow(
                distanceMeters: distanceMeters,
                elapsed: elapsed,
                hero: true,
              ),
            ),
            PawlogBottomAction(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppButton.secondary(
                    key: const Key('walk-active-pause-button'),
                    label: isPaused ? l10n.walkUnpause : l10n.walkPause,
                    onPressed: onTogglePause,
                  ),
                  const SizedBox(height: PawlogSpacing.sm),
                  PawlogPrimaryButton.stop(
                    key: const Key('walk-active-stop-button'),
                    label: l10n.walkStop,
                    onPressed: onStop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
