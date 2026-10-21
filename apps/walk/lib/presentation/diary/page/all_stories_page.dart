import 'dart:async';
import 'dart:io';

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
import '../cubit/story_covers_cubit.dart';
import '../cubit/story_manage_cubit.dart';
import '../cubit/story_manage_state.dart';
import '../format/diary_format.dart';
import '../widget/story_avatar.dart';
import '../widget/story_bar.dart';
import 'diary_route.dart';
import 'story_form_sheet.dart';
import 'story_page.dart';

/// 모든 스토리를 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openAllStories(BuildContext context) =>
    pushDiaryRoute<void>(context, page: (_) => const AllStoriesPage());

/// 스토리를 만든다(모든 스토리 앱바 ＋ · 일기 탭 동그라미 줄 `＋ 새 스토리`): 만들기 시트 →
/// 만들기 → 오늘 전에 시작했으면 그 기간의 '일상' 기록을 골라 옮기도록 제안한다.
/// 실패는 스낵바로 알린다.
Future<void> createStory(BuildContext context) async {
  final clock = getIt<Clock>();
  final input = await StoryFormSheet.create(context, now: clock.now());
  if (input == null || !context.mounted) return;
  final cubit = StoryManageCubit(
    getIt<DiaryRepository>(),
    getIt<DiaryUseCase>(),
    clock,
  );
  try {
    await cubit.create(
      title: input.title,
      startedAt: input.startedAt,
      endedAt: input.endedAt,
    );
    if (!context.mounted || _reportFailure(context, cubit.state)) return;
    final created = cubit.state.created;
    if (created == null) return;
    await _suggestMove(context, cubit, created, clock.now());
  } finally {
    await cubit.close();
  }
}

/// 마지막 동작이 실패했으면 오류 스낵바를 띄우고 true.
bool _reportFailure(BuildContext context, StoryManageState state) {
  final l10n = AppLocalizations.of(context);
  final message = switch (state) {
    StoryManageState(:final error?) => DiaryFormat.failure(l10n, error),
    StoryManageState(actionFailed: true) => l10n.walkDiaryErrorSave,
    _ => null,
  };
  if (message == null) return false;
  AppSnackBar.show(context, message: message, type: AppSnackBarType.error);
  return true;
}

/// 오늘 전에 시작한 스토리면 그 기간의 '일상' 기록을 골라 옮기게 한다.
Future<void> _suggestMove(
  BuildContext context,
  StoryManageCubit cubit,
  Story story,
  DateTime now,
) async {
  if (!story.startedAt.isBefore(DateTime(now.year, now.month, now.day))) {
    return;
  }
  final candidates = await cubit.dailyEntriesIn(
    story.startedAt,
    story.endedAt ?? now,
  );
  if (candidates.isEmpty || !context.mounted) return;
  final ids = await showModalBottomSheet<List<String>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _MoveSheet(entries: candidates, now: now),
  );
  if (ids == null || ids.isEmpty || !context.mounted) return;
  await cubit.moveIn(ids, story.id);
  if (!context.mounted || _reportFailure(context, cubit.state)) return;
  AppSnackBar.show(
    context,
    message: AppLocalizations.of(context).walkDiaryStoryMoved(ids.length),
    type: AppSnackBarType.success,
  );
}

/// 모든 스토리(스펙 §3.4, 스토리 관리 목록을 대신한다): 앱바 ＋ 로 만들기, 구역
/// **진행 중** · **지난 스토리**마다 2열 카드(정사각 표지 · 이름 · 기간 · 기록 n개).
/// 카드를 누르면 스토리 페이지(§3.3)다 — 이름 · 표지 · 닫기 · 삭제는 거기서 한다.
/// 만들기는 [createStory].
class AllStoriesPage extends StatefulWidget {
  const AllStoriesPage({super.key});

  @override
  State<AllStoriesPage> createState() => _AllStoriesPageState();
}

class _AllStoriesPageState extends State<AllStoriesPage> {
  late final _cubit = StoryManageCubit(
    getIt<DiaryRepository>(),
    getIt<DiaryUseCase>(),
    getIt<Clock>(),
  )..start();
  late final _covers = StoryCoversCubit(getIt<DiaryRepository>())..start();
  StreamSubscription<List<DiaryEntry>>? _entrySub;

  /// 스토리 id → 살아 있는 기록 수.
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _entrySub = getIt<DiaryRepository>()
        .watchEntries(const EntryFilter.all())
        .listen((entries) {
          final counts = <String, int>{};
          for (final e in entries) {
            counts[e.storyId] = (counts[e.storyId] ?? 0) + 1;
          }
          setState(() => _counts = counts);
        }, onError: (Object _) {});
  }

  @override
  void dispose() {
    unawaited(_entrySub?.cancel());
    unawaited(_cubit.close());
    unawaited(_covers.close());
    super.dispose();
  }

  DateTime get _now => getIt<Clock>().now();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _covers),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.walkDiaryAllStories),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.walkDiaryStoryNew,
              onPressed: () => createStory(context),
            ),
          ],
        ),
        body: BlocBuilder<StoryManageCubit, StoryManageState>(
          builder: (context, state) {
            if (state.failed) {
              return AppPlaceholder(
                icon: Icons.error_outline,
                message: l10n.walkDiaryLoadError,
              );
            }
            if (state.loading) return const SizedBox.shrink();
            return BlocBuilder<StoryCoversCubit, Map<String, StoryCover>>(
              builder: (context, covers) {
                final files = coverFiles(covers);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    ..._section(
                      context,
                      l10n.walkDiaryOngoing,
                      state.open,
                      files,
                    ),
                    if (state.archived.isNotEmpty)
                      ..._section(
                        context,
                        l10n.walkDiaryPastStories,
                        state.archived,
                        files,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 구역 제목 + 2열 카드 줄들.
  List<Widget> _section(
    BuildContext context,
    String title,
    List<Story> stories,
    Map<String, File> files,
  ) {
    final theme = Theme.of(context);
    Widget card(Story s) => _StoryCard(
      key: ValueKey('story-card-${s.id}'),
      story: s,
      image: files[s.id],
      count: _counts[s.id] ?? 0,
      now: _now,
      onTap: () => openStoryPage(context, s.id),
    );
    return [
      Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      for (var i = 0; i < stories.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card(stories[i])),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: i + 1 < stories.length
                    ? card(stories[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ];
  }
}

/// 스토리 카드: 정사각 표지(사진, 없으면 이니셜) · 이름 · 기간 · 기록 n개.
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.image,
    required this.count,
    required this.now,
    required this.onTap,
    super.key,
  });

  final Story story;
  final File? image;
  final int count;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = storyDisplayTitle(l10n, story);
    final trimmed = title.trim();
    final initial = Center(
      child: Text(
        trimmed.isEmpty ? '?' : trimmed.characters.first,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: colors.onPrimaryContainer,
        ),
      ),
    );
    final file = image;
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: ColoredBox(
                color: colors.primaryContainer,
                child: file == null
                    ? initial
                    : Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => initial,
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            DiaryFormat.storyPeriod(l10n, story, now),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: caption,
          ),
          Text(l10n.walkDiaryEntryCount(count), style: caption),
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
