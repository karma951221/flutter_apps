import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/tracking/entity/tracker_state.dart';
import '../../../domain/walk/entity/walk.dart';
import '../../backup/backup_messages.dart';
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
    required this.onOpenCommunity,
    super.key,
  });

  final VoidCallback onStartWalk;
  final VoidCallback onSaveWalk;
  final ValueChanged<String> onOpenWalk;
  final VoidCallback onOpenDogs;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCommunity;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<WalkFeedCubit>()..start(),
    child: _WalkFeedView(
      onStartWalk: onStartWalk,
      onSaveWalk: onSaveWalk,
      onOpenWalk: onOpenWalk,
      onOpenDogs: onOpenDogs,
      onOpenStats: onOpenStats,
      onOpenCommunity: onOpenCommunity,
    ),
  );
}

enum _FeedMenuAction { favoritesOnly, exportBackup, importBackup }

class _WalkFeedView extends StatefulWidget {
  const _WalkFeedView({
    required this.onStartWalk,
    required this.onSaveWalk,
    required this.onOpenWalk,
    required this.onOpenDogs,
    required this.onOpenStats,
    required this.onOpenCommunity,
  });

  final VoidCallback onStartWalk;
  final VoidCallback onSaveWalk;
  final ValueChanged<String> onOpenWalk;
  final VoidCallback onOpenDogs;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCommunity;

  @override
  State<_WalkFeedView> createState() => _WalkFeedViewState();
}

class _WalkFeedViewState extends State<_WalkFeedView> {
  // 주 경계를 넘긴 채 돌아오면 '이번 주' 요약을 다시 잡는다.
  late final AppLifecycleListener _lifecycle;

  VoidCallback get onStartWalk => widget.onStartWalk;
  VoidCallback get onSaveWalk => widget.onSaveWalk;
  ValueChanged<String> get onOpenWalk => widget.onOpenWalk;
  VoidCallback get onOpenDogs => widget.onOpenDogs;
  VoidCallback get onOpenStats => widget.onOpenStats;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<WalkFeedCubit>().refreshWeekSummary(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _onMenu(_FeedMenuAction action) async {
    final cubit = context.read<WalkFeedCubit>();
    switch (action) {
      case _FeedMenuAction.favoritesOnly:
        cubit.toggleFavoritesOnly();
      case _FeedMenuAction.exportBackup:
        final result = await cubit.exportBackup();
        if (!mounted || result is! Err) return;
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).walkBackupExportFailed,
          type: AppSnackBarType.error,
        );
      case _FeedMenuAction.importBackup:
        final result = await cubit.importBackup();
        if (!mounted) return;
        showBackupImportResult(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WalkFeedCubit>();

    return BlocBuilder<WalkFeedCubit, WalkFeedState>(
      builder: (context, state) {
        final favoritesOnly = state is WalkFeedLoaded && state.favoritesOnly;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.pawlogAppTitle),
            actions: [
              IconButton(
                key: const Key('walk-feed-community'),
                icon: const Icon(Icons.people_outline),
                tooltip: l10n.walkSocialOpenTooltip,
                onPressed: widget.onOpenCommunity,
              ),
              IconButton(
                key: const Key('walk-feed-open-dogs'),
                icon: const Icon(Icons.pets),
                tooltip: l10n.walkOpenDogsTooltip,
                onPressed: onOpenDogs,
              ),
              AppOverflowMenu<_FeedMenuAction>(
                key: const Key('walk-feed-more'),
                tooltip: l10n.walkFeedMoreTooltip,
                items: [
                  // 목록을 못 불러온 동안에는 거를 것이 없다 — 토글 라벨이 틀린 말을 하게 된다.
                  if (state is WalkFeedLoaded)
                    AppOverflowMenuItem(
                      key: const Key('walk-feed-favorites-toggle'),
                      value: _FeedMenuAction.favoritesOnly,
                      label: favoritesOnly
                          ? l10n.walkFeedShowAll
                          : l10n.walkFeedShowFavorites,
                      icon: favoritesOnly ? Icons.star : Icons.star_border,
                    ),
                  AppOverflowMenuItem(
                    key: const Key('walk-feed-backup-export'),
                    value: _FeedMenuAction.exportBackup,
                    label: l10n.walkBackupExport,
                    icon: Icons.ios_share,
                  ),
                  AppOverflowMenuItem(
                    key: const Key('walk-feed-backup-import'),
                    value: _FeedMenuAction.importBackup,
                    label: l10n.walkBackupImport,
                    icon: Icons.download_outlined,
                  ),
                ],
                onSelected: _onMenu,
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
              WalkFeedLoaded(
                :final walks,
                :final tracker,
                :final weekSummary,
                :final isLoadingMore,
              ) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _banner(tracker),
                    // 목록이 걸러져 오므로 즐겨찾기만 보기에서는 0건이어도 기록이 있는 피드로 친다.
                    if (walks.isNotEmpty || favoritesOnly)
                      WeekSummaryLine(summary: weekSummary, onTap: onOpenStats),
                    Expanded(
                      child: _body(
                        walks: walks,
                        tracker: tracker,
                        favoritesOnly: favoritesOnly,
                        isLoadingMore: isLoadingMore,
                      ),
                    ),
                    // 저장 · 버리기 전에는 새 산책을 막는다(finished). 0건 추적 중이면 배너가 이끈다.
                    if (tracker is TrackerIdle ||
                        (tracker is TrackerTracking &&
                            (walks.isNotEmpty || favoritesOnly)))
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
        );
      },
    );
  }

  /// 요약 줄과 하단 버튼 사이. [walks] 는 이미 걸러진(즐겨찾기만 보기면 즐겨찾기만) 읽은
  /// 페이지다. 즐겨찾기만 보기에서 0건이면 즐겨찾기 안내, 필터가 꺼진 빈 피드는 첫 산책 안내다.
  Widget _body({
    required List<Walk> walks,
    required TrackerState tracker,
    required bool favoritesOnly,
    required bool isLoadingMore,
  }) {
    final l10n = AppLocalizations.of(context);
    if (walks.isEmpty && favoritesOnly) {
      return Center(
        child: AppPlaceholder(
          message: l10n.walkFeedFavoritesEmptyTitle,
          description: l10n.walkFeedFavoritesEmptyMessage,
        ),
      );
    }
    if (walks.isEmpty) {
      return Center(
        // 수첩 첫 장 — 날짜 열 없이 안내 한 줄. 산책 중이거나 저장 전이면
        // 시작을 권하지 않는다 — 위 배너가 그 산책으로 이끈다.
        child: tracker is TrackerIdle
            ? AppPlaceholder(
                message: l10n.walkFeedEmptyTitle,
                description: l10n.walkFeedEmptyMessage,
              )
            : AppPlaceholder(
                message: l10n.walkFeedEmptyActiveTitle,
                description: l10n.walkFeedEmptyActiveMessage,
              ),
      );
    }
    final cubit = context.read<WalkFeedCubit>();
    return AppLoadMoreListener(
      onLoadMore: cubit.loadMore,
      child: _Timeline(
        walks: walks,
        isLoadingMore: isLoadingMore,
        photoFile: cubit.photoFile,
        onOpenWalk: onOpenWalk,
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
/// 페이지를 이어 붙인 전체 목록으로 그리므로 페이지 경계에서도 날짜 묶음이 이어진다.
/// 다음 페이지를 읽는 동안에만 맨 끝에 로딩 줄이 붙는다.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.walks,
    required this.isLoadingMore,
    required this.photoFile,
    required this.onOpenWalk,
  });

  final List<Walk> walks;
  final bool isLoadingMore;
  final File Function(String relativePath) photoFile;
  final ValueChanged<String> onOpenWalk;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(bottom: PawlogSpacing.sm),
    // 끝 안내는 두지 않는다 — 조용한 일기장 피드. 다음 페이지를 읽는 동안에만 스피너 한 줄.
    itemCount: walks.length + (isLoadingMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == walks.length) {
        return const AppListFooter(isLoadingMore: true, canLoadMore: true);
      }
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
