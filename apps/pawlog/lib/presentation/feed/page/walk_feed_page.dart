import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/tracking/entity/tracker_state.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../common/widget/pawlog_primary_button.dart';
import '../../theme/pawlog_theme.dart';
import '../../tracking/widget/active_walk_banner.dart';
import '../cubit/walk_feed_cubit.dart';
import '../cubit/walk_feed_state.dart';
import '../widget/walk_feed_entry.dart';
import '../widget/week_summary_line.dart';

/// 첫 화면 — 내 산책 기록의 최신순 타임라인.
///
/// 라우팅은 모른다. 저장 · 수정 · 삭제는 스트림으로 흘러와 새로고침 콜백이 없다.
class WalkFeedPage extends StatelessWidget {
  const WalkFeedPage({
    required this.onStartWalk,
    required this.onSaveWalk,
    required this.onOpenWalk,
    required this.onOpenDogs,
    required this.onOpenStats,
    super.key,
  });

  final VoidCallback onStartWalk;
  final VoidCallback onSaveWalk;
  final ValueChanged<String> onOpenWalk;
  final VoidCallback onOpenDogs;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<WalkFeedCubit>()..start(),
    child: _WalkFeedView(
      onStartWalk: onStartWalk,
      onSaveWalk: onSaveWalk,
      onOpenWalk: onOpenWalk,
      onOpenDogs: onOpenDogs,
      onOpenStats: onOpenStats,
    ),
  );
}

class _WalkFeedView extends StatelessWidget {
  const _WalkFeedView({
    required this.onStartWalk,
    required this.onSaveWalk,
    required this.onOpenWalk,
    required this.onOpenDogs,
    required this.onOpenStats,
  });

  final VoidCallback onStartWalk;
  final VoidCallback onSaveWalk;
  final ValueChanged<String> onOpenWalk;
  final VoidCallback onOpenDogs;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WalkFeedCubit>();

    return BlocBuilder<WalkFeedCubit, WalkFeedState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.pawlogAppTitle),
          actions: [
            IconButton(
              key: const Key('walk-feed-open-dogs'),
              icon: const Icon(Icons.pets),
              tooltip: l10n.walkOpenDogsTooltip,
              onPressed: onOpenDogs,
            ),
          ],
        ),
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
            WalkFeedLoaded(:final walks, :final tracker, :final weekSummary) =>
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _banner(tracker),
                  if (walks.isNotEmpty)
                    WeekSummaryLine(summary: weekSummary, onTap: onOpenStats),
                  Expanded(
                    child: walks.isEmpty
                        ? Center(
                            // 수첩 첫 장 — 날짜 열 없이 안내 한 줄. 산책 중이거나 저장 전이면
                            // 시작을 권하지 않는다 — 위 배너가 그 산책으로 이끈다.
                            child: tracker is TrackerIdle
                                ? AppPlaceholder(
                                    message: l10n.walkFeedEmptyTitle,
                                    description: l10n.walkFeedEmptyMessage,
                                  )
                                : AppPlaceholder(
                                    message: l10n.walkFeedEmptyActiveTitle,
                                    description:
                                        l10n.walkFeedEmptyActiveMessage,
                                  ),
                          )
                        : _Timeline(
                            walks: walks,
                            photoFile: cubit.photoFile,
                            onOpenWalk: onOpenWalk,
                          ),
                  ),
                  // 저장 · 버리기 전에는 새 산책을 막는다(finished). 0건 추적 중이면 배너가 이끈다.
                  if (tracker is TrackerIdle ||
                      (tracker is TrackerTracking && walks.isNotEmpty))
                    PawlogBottomAction(
                      child: PawlogPrimaryButton(
                        key: const Key('walk-feed-start-button'),
                        label: tracker is TrackerTracking
                            ? l10n.walkContinue
                            : l10n.walkStart,
                        onPressed: onStartWalk,
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

/// 날짜별 타임라인. 최신순 목록을 받아 같은 날은 날짜를 한 번만 쓰고 리드줄로 잇는다.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.walks,
    required this.photoFile,
    required this.onOpenWalk,
  });

  final List<Walk> walks;
  final File Function(String relativePath) photoFile;
  final ValueChanged<String> onOpenWalk;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(bottom: PawlogSpacing.sm),
    itemCount: walks.length,
    itemBuilder: (context, index) {
      final walk = walks[index];
      final day = walk.startedAt.toLocal();
      final previous = index == 0 ? null : walks[index - 1].startedAt.toLocal();
      final next = index + 1 < walks.length
          ? walks[index + 1].startedAt.toLocal()
          : null;
      final newMonth =
          previous == null ||
          previous.year != day.year ||
          previous.month != day.month;
      final entry = WalkFeedEntry(
        key: Key('walk-feed-entry-${walk.id}'),
        walk: walk,
        photoFile: photoFile,
        onTap: () => onOpenWalk(walk.id),
        showDate: previous == null || !_sameDay(previous, day),
        continuesBelow: next != null && _sameDay(next, day),
      );
      if (!newMonth) return entry;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WalkFeedMonthHeader(month: day),
          entry,
        ],
      );
    },
  );
}
