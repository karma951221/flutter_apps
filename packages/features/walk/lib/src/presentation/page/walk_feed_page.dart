import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/tracker_state.dart';
import '../cubit/walk_feed_cubit.dart';
import '../cubit/walk_feed_state.dart';
import '../widget/active_walk_banner.dart';
import '../widget/walk_card.dart';

/// 첫 화면 — 내 산책 기록의 최신순 타임라인.
///
/// 라우팅은 모른다. 저장 · 수정 · 삭제는 스트림으로 흘러와 새로고침 콜백이 없다.
class WalkFeedPage extends StatelessWidget {
  const WalkFeedPage({
    required this.onStartWalk,
    required this.onSaveWalk,
    required this.onOpenWalk,
    required this.onOpenDogs,
    super.key,
  });

  final VoidCallback onStartWalk;
  final VoidCallback onSaveWalk;
  final ValueChanged<String> onOpenWalk;
  final VoidCallback onOpenDogs;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<WalkFeedCubit>()..start(),
    child: _WalkFeedView(
      onStartWalk: onStartWalk,
      onSaveWalk: onSaveWalk,
      onOpenWalk: onOpenWalk,
      onOpenDogs: onOpenDogs,
    ),
  );
}

class _WalkFeedView extends StatelessWidget {
  const _WalkFeedView({
    required this.onStartWalk,
    required this.onSaveWalk,
    required this.onOpenWalk,
    required this.onOpenDogs,
  });

  final VoidCallback onStartWalk;
  final VoidCallback onSaveWalk;
  final ValueChanged<String> onOpenWalk;
  final VoidCallback onOpenDogs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WalkFeedCubit>();

    return BlocBuilder<WalkFeedCubit, WalkFeedState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.walkAppTitle),
          actions: [
            IconButton(
              key: const Key('walk-feed-open-dogs'),
              icon: const Icon(Icons.pets),
              tooltip: l10n.walkOpenDogsTooltip,
              onPressed: onOpenDogs,
            ),
          ],
        ),
        floatingActionButton: switch (state) {
          WalkFeedLoaded(:final walks, :final tracker)
              when walks.isNotEmpty && tracker is! TrackerFinished =>
            FloatingActionButton.extended(
              key: const Key('walk-feed-fab'),
              onPressed: onStartWalk,
              label: Text(
                tracker is TrackerTracking ? l10n.walkContinue : l10n.walkStart,
              ),
              icon: const Icon(Icons.directions_walk),
            ),
          _ => null,
        },
        body: SafeArea(
          child: switch (state) {
            WalkFeedLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            WalkFeedFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                actionKey: const Key('walk-feed-retry'),
                onAction: cubit.retry,
              ),
            ),
            WalkFeedLoaded(:final walks, :final tracker) => Column(
              children: [
                _banner(tracker),
                Expanded(
                  child: walks.isEmpty
                      ? Center(
                          child: AppPlaceholder(
                            icon: Icons.pets_outlined,
                            message: l10n.walkFeedEmptyTitle,
                            description: l10n.walkFeedEmptyMessage,
                            actionLabel: l10n.walkStart,
                            // 저장 안 한 산책이 있으면 새로 시작하지 않는다.
                            onAction: tracker is TrackerFinished
                                ? null
                                : onStartWalk,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.sm,
                            // FAB 에 마지막 카드가 가리지 않게.
                            bottom: AppSpacing.xl * 3,
                          ),
                          itemCount: walks.length,
                          itemBuilder: (context, index) {
                            final walk = walks[index];
                            return WalkCard(
                              key: Key('walk-feed-card-${walk.id}'),
                              walk: walk,
                              photoFile: cubit.photoFile,
                              onTap: () => onOpenWalk(walk.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }

  Widget _banner(TrackerState tracker) => switch (tracker) {
    TrackerIdle() => const SizedBox.shrink(),
    TrackerTracking(:final session) => ActiveWalkBanner.tracking(
      session: session,
      elapsed: session.elapsedAt(DateTime.now()),
      onTap: onStartWalk,
    ),
    TrackerFinished() => ActiveWalkBanner.unsaved(onTap: onSaveWalk),
  };
}
