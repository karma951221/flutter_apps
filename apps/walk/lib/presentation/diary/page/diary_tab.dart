import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_view_mode.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_cover.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../../theme/walk_theme.dart';
import '../cubit/diary_timeline_cubit.dart';
import '../cubit/diary_timeline_state.dart';
import '../cubit/story_covers_cubit.dart';
import '../widget/diary_entries_view.dart';
import '../widget/story_avatar.dart';
import '../widget/story_bar.dart';
import '../widget/story_header.dart';
import 'diary_search_page.dart';
import 'entry_detail_page.dart';
import 'entry_editor_page.dart';
import 'story_manage_page.dart';
import 'trash_page.dart';

/// 셸의 일기 탭(스펙 §6.1). 위에서 `DiaryLockCubit` 를 받는다(셸이 소유).
///
/// 타임라인은 [DiaryLockGate] 안쪽에 있어 잠긴 동안 트리에 없다. 탭이 보이고 잠금이 풀려 있게
/// 될 때마다(풀린 채 탭이 보이게 되거나, 보이는 탭에서 잠금이 풀릴 때) [DiaryUseCase.maintain] 을
/// 부른다 — 기다리지 않고 실패는 삼킨다. 잠긴 동안 부르지 않는 것은 PIN 없이 휴지통 기한이 지난
/// 기록을 영구 삭제시키지 못하게 하기 위해서다.
class DiaryTab extends StatefulWidget {
  const DiaryTab({required this.active, super.key});

  /// 셸에서 이 탭이 보이는지.
  final bool active;

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  final _useCase = getIt<DiaryUseCase>();
  late final _timeline = DiaryTimelineCubit(
    getIt<DiaryRepository>(),
    getIt<DiaryPreferences>(),
  )..start();
  late final _covers = StoryCoversCubit(getIt<DiaryRepository>())..start();

  @override
  void initState() {
    super.initState();
    if (widget.active && _unlocked) _maintain();
  }

  @override
  void didUpdateWidget(DiaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && _unlocked) _maintain();
  }

  @override
  void dispose() {
    _timeline.close();
    _covers.close();
    super.dispose();
  }

  bool get _unlocked => context.read<DiaryLockCubit>().state is LockUnlocked;

  /// 휴지통 기한 · 장소 이름 채우기. 화면을 막지 않는다 — 결과는 저장소 스트림으로 들어온다.
  void _maintain() => unawaited(_useCase.maintain().catchError((Object _) {}));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    return BlocListener<DiaryLockCubit, DiaryLockState>(
      listenWhen: (a, b) => a is! LockUnlocked && b is LockUnlocked,
      listener: (_, _) {
        if (widget.active) _maintain();
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _timeline),
          BlocProvider.value(value: _covers),
        ],
        child: BlocBuilder<DiaryTimelineCubit, DiaryTimelineState>(
          buildWhen: (a, b) => a.viewMode != b.viewMode,
          builder: (context, state) {
            // 릴스는 탭 몸통을 꽉 채운다 — 앱바 대신 위에 얹은 머리가 토글을 들고 있다.
            final reels = unlocked && state.viewMode == DiaryViewMode.reels;
            return Scaffold(
              appBar: reels
                  ? null
                  : AppBar(
                      title: Text(l10n.walkShellTabDiary),
                      actions: [
                        if (unlocked) ...[
                          const _SearchAction(),
                          const _DiaryMenu(),
                        ],
                      ],
                    ),
              // 다시 잠기면 이 탭에서 띄운 시트(보관함 등)를 닫는다 — 가려진 탭이면 위의 팝업은 다른 탭의 것.
              body: DiaryLockGate(
                dismissPopups: widget.active,
                child: _Timeline(active: widget.active),
              ),
              // 오른쪽 아래 — 릴스에서도 위에 얹은 머리 · 토글을 가리지 않는다.
              floatingActionButton: unlocked
                  ? FloatingActionButton(
                      // 셸의 IndexedStack 에 알람 탭 ＋ 도 있다 — 기본 Hero 태그가 겹치지 않게 끈다.
                      heroTag: null,
                      tooltip: l10n.walkDiaryEditorNewTitle,
                      onPressed: () => openEntryEditor(context),
                      child: const Icon(Icons.add),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// 일기 탭 앱바 🔍(스펙 §6.4). 검색에서 스토리를 고르고 돌아오면 타임라인이 그 스토리를 고른다.
class _SearchAction extends StatelessWidget {
  const _SearchAction();

  Future<void> _search(BuildContext context) async {
    final timeline = context.read<DiaryTimelineCubit>();
    final storyId = await openDiarySearch(context);
    if (storyId != null && !timeline.isClosed) timeline.selectStory(storyId);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.search),
    tooltip: AppLocalizations.of(context).walkDiarySearch,
    onPressed: () => unawaited(_search(context)),
  );
}

enum _DiaryMenuItem { stories, trash }

/// 일기 탭 앱바 ⋮(스펙 §6.1): 스토리 관리 · 휴지통. 잠긴 동안은 두지 않는다.
/// 릴스에서는 앱바가 없어 위에 얹은 머리 옆에 같은 위젯을 둔다.
/// 항목을 더하려면 [_DiaryMenuItem] 값과 [_items] · [_open] 의 한 줄씩.
class _DiaryMenu extends StatelessWidget {
  const _DiaryMenu();

  List<AppOverflowMenuItem<_DiaryMenuItem>> _items(AppLocalizations l10n) => [
    AppOverflowMenuItem(
      value: _DiaryMenuItem.stories,
      label: l10n.walkDiaryMenuStories,
      icon: Icons.auto_stories_outlined,
    ),
    AppOverflowMenuItem(
      value: _DiaryMenuItem.trash,
      label: l10n.walkDiaryMenuTrash,
      icon: Icons.delete_outline,
    ),
  ];

  Future<void> _open(BuildContext context, _DiaryMenuItem item) =>
      switch (item) {
        _DiaryMenuItem.stories => openStoryManage(context),
        _DiaryMenuItem.trash => openTrash(context),
      };

  @override
  Widget build(BuildContext context) => AppOverflowMenu<_DiaryMenuItem>(
    items: _items(AppLocalizations.of(context)),
    onSelected: (item) => unawaited(_open(context, item)),
  );
}

/// 스토리 바 + 고른 스토리의 머리 · 보기 모드 토글 + 기록.
/// 릴스에서는 기록이 몸통을 채우고, 스토리 바 없이 머리만 반투명하게 위에 얹는다.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.active});

  /// 셸에서 이 탭이 보이는지. 가려지면 릴스 영상을 멈춘다.
  final bool active;

  /// 릴스 위 머리 바탕의 불투명도.
  static const _overlayAlpha = 0.7;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DiaryTimelineCubit, DiaryTimelineState>(
        builder: (context, state) {
          final cubit = context.read<DiaryTimelineCubit>();
          final selectedId = state.selectedStoryId;
          final selected = selectedId == null
              ? null
              : [
                  ...state.openStories,
                  ...state.archived,
                ].where((s) => s.id == selectedId).firstOrNull;
          final header = StoryHeader(
            story: selected,
            now: getIt<Clock>().now(),
            mode: state.viewMode,
            onMode: cubit.setViewMode,
          );
          final entries = _Entries(state: state, active: active);
          if (state.viewMode == DiaryViewMode.reels) {
            return Stack(
              fit: StackFit.expand,
              children: [
                entries,
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Theme(
                    data: WalkTheme.dark(),
                    child: Builder(
                      builder: (context) => ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: _overlayAlpha),
                        // 앱바가 없으니 🔍 · ⋮ 를 머리 옆에 둔다(R25) — 앱바와 같은 위젯.
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: header),
                              const _SearchAction(),
                              const _DiaryMenu(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<StoryCoversCubit, Map<String, StoryCover>>(
                builder: (context, covers) => StoryBar(
                  open: state.openStories,
                  archived: state.archived,
                  selectedId: selectedId,
                  onSelect: cubit.selectStory,
                  covers: coverFiles(covers),
                ),
              ),
              const Divider(height: 1),
              header,
              Expanded(child: entries),
            ],
          );
        },
      );
}

/// 기록 목록을 고른 보기 모드로. 읽지 못했으면 오류 안내, 비었으면 빈 상태 안내.
class _Entries extends StatelessWidget {
  const _Entries({required this.state, required this.active});

  final DiaryTimelineState state;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.failed) {
      return AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkDiaryLoadError,
      );
    }
    if (state.loading) return const SizedBox.shrink();
    final entries = state.entries;
    if (entries.isEmpty) {
      return AppPlaceholder(
        icon: Icons.menu_book_outlined,
        message: l10n.walkDiaryEmpty,
      );
    }
    return DiaryEntriesView(
      // 스토리를 바꾸면 스크롤 · 릴스 페이지를 처음부터.
      key: ValueKey(state.selectedStoryId),
      mode: state.viewMode,
      entries: entries,
      showStoryName: state.selectedStoryId == null,
      active: active,
      storyTitles: {
        for (final s in [...state.openStories, ...state.archived])
          s.id: storyDisplayTitle(l10n, s),
      },
      onOpen: (entry) => openEntryDetail(context, entry.id),
    );
  }
}
