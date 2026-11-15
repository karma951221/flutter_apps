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
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../../settings/open_settings.dart';
import '../../shell/widget/feature_menu.dart';
import '../cubit/diary_timeline_cubit.dart';
import '../cubit/diary_timeline_state.dart';
import '../viewer/story_viewer_page.dart';
import '../widget/feed_view.dart';
import '../widget/story_avatar.dart';
import 'all_stories_page.dart';
import 'diary_search_page.dart';
import 'entry_actions.dart';
import 'entry_editor_page.dart';
import 'filtered_entries_page.dart';
import 'story_page.dart';
import 'trash_page.dart';

/// 기록 탭 › 일기(스펙 2026-11-15 F4, 일반 피드): 모든 스토리 기록 피드. 스토리 동그라미 줄은
/// 두지 않는다 — 스토리는 ⋮ 모든 스토리 · 카드의 스토리 이름으로 간다.
/// 위에서 `DiaryLockCubit` 를 받는다(셸이 소유). 앱바는 기록 탭(`LogTab`)의 것이고, 일기일 때 그
/// 앱바에 [DiarySearchAction] · [DiaryMenu] 를 단다. ⋮ 의 설정 항목은 셸의 설정 cubit 아래에서
/// 연다([openSettings]). ＋ 는 셸이 이 상단 탭일 때 [DiaryNewEntryButton] 으로 둔다.
///
/// 타임라인은 [DiaryLockGate] 안쪽에 있어 잠긴 동안 트리에 없다. 탭이 보이고 잠금이 풀려 있게
/// 될 때마다(풀린 채 탭이 보이게 되거나, 보이는 탭에서 잠금이 풀릴 때) [DiaryUseCase.maintain] 을
/// 부른다 — 기다리지 않고 실패는 삼킨다. 잠긴 동안 부르지 않는 것은 PIN 없이 휴지통 기한이 지난
/// 기록을 영구 삭제시키지 못하게 하기 위해서다.
class DiaryTab extends StatefulWidget {
  const DiaryTab({required this.active, super.key});

  /// 하단 탭이 기록이고 상단 탭이 일기인지.
  final bool active;

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  final _useCase = getIt<DiaryUseCase>();
  late final _timeline = DiaryTimelineCubit(getIt<DiaryRepository>())..start();

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
    super.dispose();
  }

  bool get _unlocked => context.read<DiaryLockCubit>().state is LockUnlocked;

  /// 휴지통 기한 · 장소 이름 채우기. 화면을 막지 않는다 — 결과는 저장소 스트림으로 들어온다.
  void _maintain() => unawaited(_useCase.maintain().catchError((Object _) {}));

  @override
  Widget build(BuildContext context) =>
      BlocListener<DiaryLockCubit, DiaryLockState>(
        listenWhen: (a, b) => a is! LockUnlocked && b is LockUnlocked,
        listener: (_, _) {
          if (widget.active) _maintain();
        },
        child: BlocProvider.value(
          value: _timeline,
          // 다시 잠기면 이 탭에서 띄운 팝업(카드 ⋮ 등)을 닫는다 — 가려진 탭이면 위의 팝업은 다른 탭의 것.
          child: DiaryLockGate(
            dismissPopups: widget.active,
            child: const _Timeline(),
          ),
        ),
      );
}

/// 일기 탭의 ＋(새 기록 — 작성 화면을 바로 연다). 잠긴 동안은 두지 않는다.
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
      // 셸의 IndexedStack 에 도구 › 알람의 ＋ 도 있다 — 기본 Hero 태그가 겹치지 않게 끈다.
      heroTag: null,
      tooltip: AppLocalizations.of(context).walkDiaryEditorNewTitle,
      onPressed: () => unawaited(_post(context)),
      child: const Icon(Icons.add),
    );
  }

  /// 스펙 2026-11-15 F1: 시트 없이 작성 화면을 바로 연다. 사진은 작성 화면 도구줄에서 붙인다.
  static Future<void> _post(BuildContext context) => openEntryEditor(context);
}

/// 기록 탭 앱바 🔍(일기일 때, 스펙 §6.4). 검색 화면이 결과를 직접 연다.
class DiarySearchAction extends StatelessWidget {
  const DiarySearchAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.search),
    tooltip: AppLocalizations.of(context).walkDiarySearch,
    onPressed: () => unawaited(openDiarySearch(context)),
  );
}

/// 기록 탭 앱바 ⋮(일기일 때, 스펙 §3.1): 모든 스토리 · 휴지통 · 일기 설정 · 앱 설정.
/// 잠긴 동안은 앱 설정만 — 나머지는 잠금 아래다.
class DiaryMenu extends StatelessWidget {
  const DiaryMenu({required this.unlocked, super.key});

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

/// 피드. 카드의 사진은 그 기록만 전체 화면 뷰어로 연다.
class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DiaryTimelineCubit, DiaryTimelineState>(
        builder: (context, state) {
          final body = _body(context, state);
          if (body != null) return body;
          final stories = {
            for (final s in [...state.openStories, ...state.archived]) s.id: s,
          };
          return FeedView(
            entries: state.entries,
            now: getIt<Clock>().now(),
            stories: stories,
            onOpen: (entry) => _openEntry(context, stories, entry),
            onOpenStory: (story) => unawaited(openStoryPage(context, story.id)),
            onTag: (tag) =>
                unawaited(openFilteredEntries(context, EntryFilter.tag(tag))),
            onAction: (entry, action) =>
                unawaited(_act(context, entry, action)),
          );
        },
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

  /// 그 기록만 전체 화면 뷰어로. 머리 제목은 그 기록의 스토리 이름('일상' 포함).
  void _openEntry(
    BuildContext context,
    Map<String, Story> stories,
    DiaryEntry entry,
  ) {
    final story = stories[entry.storyId];
    final title = story == null
        ? ''
        : storyDisplayTitle(AppLocalizations.of(context), story);
    unawaited(
      openStoryViewer(
        context,
        ViewerSource.entries([entry.id], title),
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
