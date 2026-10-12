import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_cover.dart';
import '../cubit/story_covers_cubit.dart';
import '../cubit/story_manage_cubit.dart';
import '../cubit/story_manage_state.dart';
import '../format/diary_format.dart';
import '../widget/entry_media_view.dart';
import '../widget/story_avatar.dart';
import '../widget/story_bar.dart';
import 'diary_route.dart';
import 'story_form_sheet.dart';

/// 스토리 관리를 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openStoryManage(BuildContext context) =>
    pushDiaryRoute<void>(context, page: (_) => const StoryManagePage());

enum _StoryAction { rename, cover, close, reopen, delete }

/// 스토리 관리(스펙 §6.3): 열린 스토리 · 보관함 목록, ＋ 로 만들기, 스토리마다 ⋮ 로
/// 이름 · 표지 · 닫기/다시 열기 · 삭제. 기본 스토리(일상)는 닫기 · 삭제가 없다.
///
/// 지난 기간으로 만들면 그 기간의 '일상' 기록을 골라 옮기도록 제안한다.
class StoryManagePage extends StatefulWidget {
  const StoryManagePage({super.key});

  @override
  State<StoryManagePage> createState() => _StoryManagePageState();
}

class _StoryManagePageState extends State<StoryManagePage> {
  late final _cubit = StoryManageCubit(
    getIt<DiaryRepository>(),
    getIt<DiaryUseCase>(),
    getIt<Clock>(),
  )..start();
  late final _covers = StoryCoversCubit(getIt<DiaryRepository>())..start();

  @override
  void dispose() {
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

  Future<void> _create() async {
    final input = await StoryFormSheet.create(context, now: _now);
    if (input == null || !mounted) return;
    await _cubit.create(
      title: input.title,
      startedAt: input.startedAt,
      endedAt: input.endedAt,
    );
    final created = _cubit.state.created;
    if (created == null || !mounted) return;
    await _suggestMove(created);
  }

  /// 오늘 전에 시작한 스토리면 그 기간의 '일상' 기록을 골라 옮기게 한다.
  Future<void> _suggestMove(Story story) async {
    final now = _now;
    if (!story.startedAt.isBefore(DateTime(now.year, now.month, now.day))) {
      return;
    }
    final candidates = await _cubit.dailyEntriesIn(
      story.startedAt,
      story.endedAt ?? now,
    );
    if (candidates.isEmpty || !mounted) return;
    final ids = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _MoveSheet(entries: candidates, now: now),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    await _cubit.moveIn(ids, story.id);
    if (_succeeded && mounted) {
      AppSnackBar.show(
        context,
        message: AppLocalizations.of(context).walkDiaryStoryMoved(ids.length),
        type: AppSnackBarType.success,
      );
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
        if (confirmed) await _cubit.delete(story.id);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _covers),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.walkDiaryMenuStories)),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          tooltip: l10n.walkDiaryStoryNew,
          onPressed: _create,
          child: const Icon(Icons.add),
        ),
        body: BlocConsumer<StoryManageCubit, StoryManageState>(
          listenWhen: (a, b) =>
              (a.error == null && b.error != null) ||
              (!a.actionFailed && b.actionFailed),
          listener: _onState,
          builder: (context, state) {
            if (state.failed) {
              return AppPlaceholder(
                icon: Icons.error_outline,
                message: l10n.walkDiaryLoadError,
              );
            }
            if (state.loading) return const SizedBox.shrink();
            final theme = Theme.of(context);
            return BlocBuilder<StoryCoversCubit, Map<String, StoryCover>>(
              builder: (context, covers) {
                final files = coverFiles(covers);
                Widget tile(Story s) => _StoryTile(
                  story: s,
                  image: files[s.id],
                  now: _now,
                  onAction: (action) => _onAction(s, action),
                );
                return ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl * 2),
                  children: [
                    for (final s in state.open) tile(s),
                    if (state.archived.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          l10n.walkDiaryArchive,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final s in state.archived) tile(s),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.story,
    required this.image,
    required this.now,
    required this.onAction,
  });

  final Story story;
  final File? image;
  final DateTime now;
  final ValueChanged<_StoryAction> onAction;

  /// 목록 행 앞 원 반지름 — `ListTile` 앞자리(40)에 맞춘 이 위젯의 크기다.
  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = storyDisplayTitle(l10n, story);
    return AppListTile(
      leading: StoryCoverCircle(label: title, image: image, radius: _radius),
      title: Text(title),
      subtitle: Text(DiaryFormat.storyPeriod(l10n, story, now)),
      trailing: AppOverflowMenu<_StoryAction>(
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
        onSelected: onAction,
      ),
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

/// 지난 기간 스토리를 만든 뒤: 그 기간의 '일상' 기록을 보이고(처음엔 모두 고름) 고른 id 로 닫힌다.
class _MoveSheet extends StatefulWidget {
  const _MoveSheet({required this.entries, required this.now});

  final List<DiaryEntry> entries;
  final DateTime now;

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  late final _selected = {for (final e in widget.entries) e.id};

  void _toggle(String id) => setState(() {
    if (!_selected.remove(id)) _selected.add(id);
  });

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
              l10n.walkDiaryStoryMoveTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final e in widget.entries)
                  AppListTile(
                    leading: Checkbox(
                      value: _selected.contains(e.id),
                      onChanged: (_) => _toggle(e.id),
                    ),
                    title: Text(
                      e.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l10n.walkDiaryEntryDateTime(
                        DiaryFormat.dateWithWeekday(
                          l10n,
                          e.occurredAt,
                          widget.now,
                        ),
                        DiaryFormat.time(context, e.occurredAt),
                      ),
                    ),
                    onTap: () => _toggle(e.id),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: AppButton.primary(
              label: l10n.walkDiaryStoryMoveConfirm(_selected.length),
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop([
                      for (final e in widget.entries)
                        if (_selected.contains(e.id)) e.id,
                    ]),
            ),
          ),
          AppButton.text(
            label: l10n.walkDiaryStoryMoveSkip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
