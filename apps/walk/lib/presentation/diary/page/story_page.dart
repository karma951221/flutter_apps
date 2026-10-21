import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_cover.dart';
import '../cubit/story_covers_cubit.dart';
import '../cubit/story_manage_cubit.dart';
import '../cubit/story_manage_state.dart';
import '../format/diary_format.dart';
import '../viewer/story_viewer_page.dart';
import '../widget/entry_grid.dart';
import '../widget/entry_media_view.dart';
import '../widget/story_avatar.dart';
import 'diary_route.dart';
import 'story_form_sheet.dart';

/// 스토리 페이지를 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openStoryPage(BuildContext context, String storyId) =>
    pushDiaryRoute<void>(context, page: (_) => StoryPage(storyId: storyId));

enum _StoryAction { rename, cover, close, reopen, delete }

/// 스토리 페이지(스펙 §3.3, 인스타 프로필/하이라이트): 머리(큰 표지 원 · 기간 · 기록 n ·
/// 사진 n · 처음부터 보기) + 기록 3열 그리드. 칸을 누르면 그 기록부터 뷰어다.
///
/// 앱바 ⋮ 는 이름 · 표지 · 닫기/다시 열기 · 삭제. 기본 스토리(일상)는 닫기 · 삭제가 없다.
/// 삭제가 성공하면 페이지를 닫는다.
class StoryPage extends StatefulWidget {
  const StoryPage({required this.storyId, super.key});

  final String storyId;

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  late final _cubit = StoryManageCubit(
    getIt<DiaryRepository>(),
    getIt<DiaryUseCase>(),
    getIt<Clock>(),
  )..start();
  late final _covers = StoryCoversCubit(getIt<DiaryRepository>())..start();
  StreamSubscription<List<DiaryEntry>>? _entrySub;

  /// 그 스토리의 살아 있는 기록. 아직 받지 못했으면 null.
  List<DiaryEntry>? _entries;
  var _entriesFailed = false;

  @override
  void initState() {
    super.initState();
    _entrySub = getIt<DiaryRepository>()
        .watchEntries(EntryFilter.story(widget.storyId))
        .listen(
          (entries) => setState(() {
            _entries = entries;
            _entriesFailed = false;
          }),
          onError: (Object _) => setState(() => _entriesFailed = true),
        );
  }

  @override
  void dispose() {
    unawaited(_entrySub?.cancel());
    unawaited(_cubit.close());
    unawaited(_covers.close());
    super.dispose();
  }

  DateTime get _now => getIt<Clock>().now();

  /// 동작을 기다린 뒤 성공이면 true. 실패는 [_onState] 가 알린다.
  bool get _succeeded =>
      _cubit.state.error == null && !_cubit.state.actionFailed;

  void _onState(BuildContext context, StoryManageState state) {
    final l10n = AppLocalizations.of(context);
    final message = switch (state) {
      StoryManageState(:final error?) => DiaryFormat.failure(l10n, error),
      StoryManageState(actionFailed: true) => l10n.walkDiaryErrorSave,
      _ => null,
    };
    if (message != null) {
      AppSnackBar.show(context, message: message, type: AppSnackBarType.error);
    }
  }

  Future<void> _onAction(Story story, _StoryAction action) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _StoryAction.rename:
        final title = await StoryFormSheet.rename(
          context,
          initialTitle: story.title,
          allowEmpty: story.isDefault,
        );
        if (title != null) await _cubit.rename(story.id, title);
      case _StoryAction.cover:
        await _pickCover(story);
      case _StoryAction.close:
        await _close(story);
      case _StoryAction.reopen:
        await _cubit.reopen(story.id);
      case _StoryAction.delete:
        final confirmed = await AppConfirmDialog.show(
          context,
          title: l10n.walkDiaryStoryDeleteTitle(storyDisplayTitle(l10n, story)),
          content: l10n.walkDiaryStoryDeleteContent,
          confirmLabel: l10n.walkDiaryStoryDelete,
        );
        if (!confirmed) return;
        await _cubit.delete(story.id);
        if (_succeeded && mounted) Navigator.of(context).pop();
    }
  }

  /// 지금 닫거나, 날짜를 골라 그날 끝으로 닫는다.
  Future<void> _close(Story story) async {
    final l10n = AppLocalizations.of(context);
    final onDate = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(l10n.walkDiaryStoryCloseNow),
              onTap: () => Navigator.of(context).pop(false),
            ),
            AppListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.walkDiaryStoryCloseOnDate),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (onDate == null || !mounted) return;
    if (!onDate) return _cubit.closeStory(story.id);
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      story.startedAt.year,
      story.startedAt.month,
      story.startedAt.day,
    );
    final day = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: start.isAfter(today) ? today : start,
      lastDate: today,
    );
    if (day == null) return;
    await _cubit.closeStory(story.id, at: StoryFormSheet.endOfDay(day, now));
  }

  Future<void> _pickCover(Story story) async {
    final candidates = await _cubit.coverCandidates(story.id);
    if (!mounted) return;
    final choice = await showModalBottomSheet<({String? mediaId})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          _CoverSheet(media: candidates, selectedId: story.coverMediaId),
    );
    if (choice == null) return;
    await _cubit.setCover(story.id, choice.mediaId);
  }

  Story? _story(StoryManageState state) => [
    ...state.open,
    ...state.archived,
  ].where((s) => s.id == widget.storyId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _covers),
      ],
      child: BlocConsumer<StoryManageCubit, StoryManageState>(
        listenWhen: (a, b) =>
            (a.error == null && b.error != null) ||
            (!a.actionFailed && b.actionFailed),
        listener: _onState,
        builder: (context, state) {
          final story = _story(state);
          if (story == null) {
            // 읽는 중 · 지워짐: 앱바만 둔다.
            return Scaffold(
              appBar: AppBar(),
              body: state.failed || _entriesFailed
                  ? AppPlaceholder(
                      icon: Icons.error_outline,
                      message: l10n.walkDiaryLoadError,
                    )
                  : null,
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(storyDisplayTitle(l10n, story)),
              actions: [
                _StoryMenu(
                  story: story,
                  onSelected: (action) => _onAction(story, action),
                ),
              ],
            ),
            body: _body(context, story),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, Story story) {
    final l10n = AppLocalizations.of(context);
    final entries = _entries ?? const <DiaryEntry>[];
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BlocBuilder<StoryCoversCubit, Map<String, StoryCover>>(
            builder: (context, covers) => _StoryHead(
              story: story,
              cover: coverFiles(covers)[story.id],
              entries: _entries,
              now: _now,
              onPlay: entries.isEmpty
                  ? null
                  : () => openStoryViewer(
                      context,
                      ViewerSource.stories([story.id]),
                      fromStart: true,
                    ),
            ),
          ),
        ),
        if (_entriesFailed)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppPlaceholder(
              icon: Icons.error_outline,
              message: l10n.walkDiaryLoadError,
            ),
          )
        else if (_entries == null)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppPlaceholder(
              icon: Icons.auto_stories_outlined,
              message: l10n.walkDiaryEmpty,
            ),
          )
        else
          SliverEntryGrid(
            entries: entries,
            onOpen: (entry) => openStoryViewer(
              context,
              ViewerSource.stories([story.id]),
              entryId: entry.id,
            ),
          ),
      ],
    );
  }
}

/// 머리: 큰 표지 원 · `기간 · 기록 n · 사진 n` · 처음부터 보기([onPlay] 가 null 이면 두지 않는다).
class _StoryHead extends StatelessWidget {
  const _StoryHead({
    required this.story,
    required this.cover,
    required this.entries,
    required this.now,
    required this.onPlay,
  });

  final Story story;
  final File? cover;

  /// 아직 받지 못했으면 null — 기록 · 사진 수는 보이지 않는다.
  final List<DiaryEntry>? entries;
  final DateTime now;
  final VoidCallback? onPlay;

  /// 머리 표지 원 반지름. 시각 토큰이 아니라 이 위젯의 크기다.
  static const _radius = 44.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final loaded = entries;
    final period = DiaryFormat.storyPeriod(l10n, story, now);
    final stats = loaded == null
        ? null
        : l10n.walkDiaryStoryStats(
            loaded.length,
            loaded
                .expand((e) => e.media)
                .where((m) => m.kind == MediaKind.photo)
                .length,
          );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          StoryCoverCircle(
            label: storyDisplayTitle(l10n, story),
            image: cover,
            radius: _radius,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            stats == null ? period : '$period · $stats',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onPlay != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: l10n.walkDiaryPlayFromStart,
              onPressed: onPlay,
            ),
          ],
        ],
      ),
    );
  }
}

/// 앱바 ⋮: 이름 · 표지 · 닫기(열린 · 일상 아님)/다시 열기(닫힘) · 삭제(일상 아님).
class _StoryMenu extends StatelessWidget {
  const _StoryMenu({required this.story, required this.onSelected});

  final Story story;
  final ValueChanged<_StoryAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppOverflowMenu<_StoryAction>(
      items: [
        AppOverflowMenuItem(
          value: _StoryAction.rename,
          label: l10n.walkDiaryStoryRename,
          icon: Icons.edit_outlined,
        ),
        AppOverflowMenuItem(
          value: _StoryAction.cover,
          label: l10n.walkDiaryStoryCover,
          icon: Icons.image_outlined,
        ),
        if (!story.isDefault && story.isOpen)
          AppOverflowMenuItem(
            value: _StoryAction.close,
            label: l10n.walkDiaryStoryClose,
            icon: Icons.inventory_2_outlined,
          ),
        if (!story.isOpen)
          AppOverflowMenuItem(
            value: _StoryAction.reopen,
            label: l10n.walkDiaryStoryReopen,
            icon: Icons.unarchive_outlined,
          ),
        if (!story.isDefault)
          AppOverflowMenuItem(
            value: _StoryAction.delete,
            label: l10n.walkDiaryStoryDelete,
            icon: Icons.delete_outline,
            isDestructive: true,
          ),
      ],
      onSelected: onSelected,
    );
  }
}

/// 표지 고르기: 맨 위 '자동' + 그 스토리 미디어 격자. 고르면 `(mediaId: …)` 로 닫힌다
/// (자동은 null). 영상은 썸네일로 보인다.
class _CoverSheet extends StatelessWidget {
  const _CoverSheet({required this.media, required this.selectedId});

  final List<EntryMedia> media;
  final String? selectedId;

  /// 격자 한 줄 칸 수.
  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.walkDiaryStoryCover,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(l10n.walkDiaryStoryCoverAuto),
            trailing: selectedId == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop((mediaId: null)),
          ),
          if (media.isEmpty)
            AppPlaceholder(
              icon: Icons.photo_outlined,
              message: l10n.walkDiaryStoryCoverEmpty,
            )
          else
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: _columns,
                padding: const EdgeInsets.all(AppSpacing.sm),
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                children: [
                  for (final m in media)
                    InkWell(
                      key: ValueKey('cover-${m.id}'),
                      onTap: () => Navigator.of(context).pop((mediaId: m.id)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.smAll,
                            child: EntryMediaView(media: m),
                          ),
                          if (m.id == selectedId)
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
