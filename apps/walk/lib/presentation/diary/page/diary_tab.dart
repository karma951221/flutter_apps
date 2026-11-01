import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_cover.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../../settings/open_settings.dart';
import '../../shell/widget/feature_menu.dart';
import '../cubit/diary_timeline_cubit.dart';
import '../cubit/diary_timeline_state.dart';
import '../cubit/story_covers_cubit.dart';
import '../viewer/story_viewer_page.dart';
import '../widget/feed_view.dart';
import '../widget/media_source_sheet.dart';
import '../widget/story_avatar.dart';
import '../widget/story_ring.dart';
import '../widget/story_ring_row.dart';
import 'all_stories_page.dart';
import 'diary_search_page.dart';
import 'entry_actions.dart';
import 'entry_editor_page.dart';
import 'filtered_entries_page.dart';
import 'story_page.dart';
import 'trash_page.dart';

/// 셸의 일기 탭(스펙 §3.1, 인스타 홈): 앱바(일기 🔍 ⋮) + 스토리 동그라미 줄 + 모든 스토리
/// 기록 피드. 위에서 `DiaryLockCubit` 를 받는다(셸이 소유). ⋮ 의 설정 항목은 셸의 설정 cubit
/// 아래에서 연다([openSettings]).
/// ＋ 는 셸이 이 탭일 때 [DiaryNewEntryButton] 으로 둔다.
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
  late final _timeline = DiaryTimelineCubit(getIt<DiaryRepository>())..start();
  late final _covers = StoryCoversCubit(getIt<DiaryRepository>())..start();

  /// 앱바를 다시 펼칠 때 바깥(앱바) 스크롤을 맨 위로 되돌린다.
  final _scroll = GlobalKey<NestedScrollViewState>();

  @override
  void initState() {
    super.initState();
    if (widget.active && _unlocked) _maintain();
  }

  @override
  void didUpdateWidget(DiaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _expandAppBar();
      if (_unlocked) _maintain();
    }
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

  /// 스크롤로 숨은 앱바를 펼친다(탭으로 돌아올 때 · 다시 잠길 때). 아직 붙어 있지 않으면 그대로.
  void _expandAppBar() {
    final outer = _scroll.currentState?.outerController;
    if (outer != null && outer.hasClients) outer.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    return MultiBlocListener(
      listeners: [
        BlocListener<DiaryLockCubit, DiaryLockState>(
          listenWhen: (a, b) => a is! LockUnlocked && b is LockUnlocked,
          listener: (_, _) {
            if (widget.active) _maintain();
          },
        ),
        // 잠금 화면에서는 앱바가 숨어 있을 까닭이 없다 — 잠긴 상태로 바뀌면 펼친다.
        BlocListener<DiaryLockCubit, DiaryLockState>(
          listenWhen: (a, b) => a is LockUnlocked && b is! LockUnlocked,
          listener: (_, _) => _expandAppBar(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _timeline),
          BlocProvider.value(value: _covers),
        ],
        child: Scaffold(
          // 앱바는 내리면 숨고 조금 올리면 다시 나온다(스펙 §5). 애니메이션 줄이기면 튀어나오는
          // 전환(snap) 없이 손가락만 따라온다.
          body: NestedScrollView(
            key: _scroll,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                title: Text(l10n.walkShellTabDiary),
                floating: true,
                snap: AppMotion.enabled(context),
                actions: [
                  if (unlocked) const _SearchAction(),
                  _DiaryMenu(unlocked: unlocked),
                ],
              ),
            ],
            // 다시 잠기면 이 탭에서 띄운 시트(새 스토리 등)를 닫는다 — 가려진 탭이면 위의 팝업은 다른 탭의 것.
            body: DiaryLockGate(
              dismissPopups: widget.active,
              child: const _Timeline(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 일기 탭의 ＋(새 기록 — 고르기 시트 먼저). 잠긴 동안은 두지 않는다.
///
/// 탭 `Scaffold` 가 아니라 셸 `Scaffold` 의 `floatingActionButton` 에 둔다 — 스낵바(휴지통으로
/// 옮기기 · 되살리기처럼 위에 얹힌 화면에서 띄운 것)는 앱 전체 메신저의 바깥 `Scaffold`(셸)에만
/// 뜨므로, 같은 `Scaffold` 에 있어야 ＋ 가 스낵바 위로 비킨다.
class DiaryNewEntryButton extends StatelessWidget {
  const DiaryNewEntryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    if (!unlocked) return const SizedBox.shrink();
    return FloatingActionButton(
      // 셸의 IndexedStack 에 알람 탭 ＋ 도 있다 — 기본 Hero 태그가 겹치지 않게 끈다.
      heroTag: null,
      tooltip: AppLocalizations.of(context).walkDiaryEditorNewTitle,
      onPressed: () => unawaited(_post(context)),
      child: const Icon(Icons.add),
    );
  }

  /// 스펙 §3.6: 고르기 시트를 먼저 띄운다. 앨범 · 카메라면 작성 화면이 열리며 그 고르기를
  /// 실행하고, 글만이면 미디어 없이 연다. 시트를 닫으면 아무것도 열지 않는다.
  static Future<void> _post(BuildContext context) async {
    final choice = await showMediaSourceSheet(context, textOnly: true);
    if (choice == null || !context.mounted) return;
    await openEntryEditor(context, initialPick: choice.source);
  }
}

/// 일기 탭 앱바 🔍(스펙 §6.4). 검색 화면이 결과를 직접 연다.
class _SearchAction extends StatelessWidget {
  const _SearchAction();

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.search),
    tooltip: AppLocalizations.of(context).walkDiarySearch,
    onPressed: () => unawaited(openDiarySearch(context)),
  );
}

/// 일기 탭 앱바 ⋮(스펙 §3.1): 모든 스토리 · 휴지통 · 일기 설정 · 앱 설정.
/// 잠긴 동안은 앱 설정만 — 나머지는 잠금 아래다.
class _DiaryMenu extends StatelessWidget {
  const _DiaryMenu({required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return const FeatureMenu(
        settings: SettingsTarget.diary,
        showFeatureSettings: false,
      );
    }
    final l10n = AppLocalizations.of(context);
    return FeatureMenu(
      settings: SettingsTarget.diary,
      entries: [
        FeatureMenuEntry(
          key: const Key('menu-diary-stories'),
          label: l10n.walkDiaryAllStories,
          icon: Icons.auto_stories_outlined,
          onTap: () => unawaited(openAllStories(context)),
        ),
        FeatureMenuEntry(
          key: const Key('menu-diary-trash'),
          label: l10n.walkDiaryMenuTrash,
          icon: Icons.delete_outline,
          onTap: () => unawaited(openTrash(context)),
        ),
      ],
    );
  }
}

/// 동그라미 줄 + 피드. 동그라미 · 카드가 여는 뷰어는 줄 순서([ringOrder])로 스토리를 넘긴다.
class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DiaryTimelineCubit, DiaryTimelineState>(
        builder: (context, state) =>
            BlocBuilder<StoryCoversCubit, Map<String, StoryCover>>(
              builder: (context, covers) {
                final files = coverFiles(covers);
                final ring = ringOrder(state.openStories, state.archived);
                final ids = [for (final s in ring) s.id];
                final rings = StoryRingRow(
                  open: state.openStories,
                  archived: state.archived,
                  covers: files,
                  onCreate: () => unawaited(createStory(context)),
                  onOpen: (story) => _openRing(context, state, ids, story),
                  onLongPress: (story) =>
                      unawaited(openStoryPage(context, story.id)),
                  onSeeAll: () => unawaited(openAllStories(context)),
                );
                final body = _body(context, state);
                if (body != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      rings,
                      const Divider(height: 1),
                      Expanded(child: body),
                    ],
                  );
                }
                return FeedView(
                  entries: state.entries,
                  now: getIt<Clock>().now(),
                  stories: {
                    for (final s in [...state.openStories, ...state.archived])
                      s.id: s,
                  },
                  covers: files,
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [rings, const Divider(height: 1)],
                  ),
                  onOpen: (entry) => _openEntry(context, ids, entry),
                  onOpenStory: (story) =>
                      unawaited(openStoryPage(context, story.id)),
                  onTag: (tag) => unawaited(
                    openFilteredEntries(context, EntryFilter.tag(tag)),
                  ),
                  onAction: (entry, action) =>
                      unawaited(_act(context, entry, action)),
                );
              },
            ),
      );

  /// 피드 대신 보일 안내: 읽지 못했으면 오류, 비었으면 빈 상태. 아직 받는 중이면 빈칸.
  /// 피드를 보이면 null.
  Widget? _body(BuildContext context, DiaryTimelineState state) {
    final l10n = AppLocalizations.of(context);
    if (state.failed) {
      return AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkDiaryLoadError,
      );
    }
    if (state.loading) return const SizedBox.shrink();
    if (state.entries.isEmpty) {
      return AppPlaceholder(
        icon: Icons.menu_book_outlined,
        message: l10n.walkDiaryEmpty,
      );
    }
    return null;
  }

  /// 기록이 있는 스토리면 그 순번부터 뷰어(진행 중이면 마지막 날, 지난 스토리면 첫날 —
  /// 뷰어가 정한다), 없으면 스토리 페이지.
  void _openRing(
    BuildContext context,
    DiaryTimelineState state,
    List<String> ids,
    Story story,
  ) {
    final posted = state.entries.any((e) => e.storyId == story.id);
    if (!posted) {
      unawaited(openStoryPage(context, story.id));
      return;
    }
    unawaited(
      openStoryViewer(
        context,
        ViewerSource.stories(ids),
        group: ids.indexOf(story.id),
      ),
    );
  }

  /// 그 기록부터 뷰어. 그 스토리가 줄 밖(오래된 닫힌 스토리)이면 그 스토리만 본다.
  void _openEntry(BuildContext context, List<String> ids, DiaryEntry entry) {
    final group = ids.indexOf(entry.storyId);
    unawaited(
      openStoryViewer(
        context,
        ViewerSource.stories(group < 0 ? [entry.storyId] : ids),
        group: group < 0 ? 0 : group,
        entryId: entry.id,
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    DiaryEntry entry,
    FeedEntryAction action,
  ) async {
    switch (action) {
      case FeedEntryAction.edit:
        await editEntry(context, entry);
      case FeedEntryAction.move:
        await moveEntry(context, entry);
      case FeedEntryAction.trash:
        await trashEntry(context, entry);
    }
  }
}
