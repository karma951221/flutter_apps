import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../format/diary_format.dart';
import '../widget/entry_media_view.dart';
import '../widget/entry_meta.dart';
import '../widget/story_bar.dart';
import 'diary_route.dart';
import 'entry_editor_page.dart';

/// 기록 상세를 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openEntryDetail(BuildContext context, String entryId) =>
    pushDiaryRoute<void>(
      context,
      page: (_) => EntryDetailPage(entryId: entryId),
    );

enum _EntryAction { edit, delete }

/// 기록 하나를 크게 본다: 미디어 · 날짜 시각 · 장소 · 글 · 태그. ⋮ 로 수정 · 삭제(휴지통).
///
/// 수정 화면을 닫고 돌아오면 기록을 다시 읽는다. 휴지통 · 영구 삭제된 기록이면 없다고 안내한다.
class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({
    required this.entryId,
    this.videoBuilder = videoSurface,
    super.key,
  });

  final String entryId;
  final VideoSurfaceBuilder videoBuilder;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  final _repo = getIt<DiaryRepository>();
  late final _stories = _repo.watchStories();

  DiaryEntry? _entry;
  var _loading = true;

  /// 삭제 중 ⋮ 를 다시 누르지 않게.
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await _repo.entry(widget.entryId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _entry = switch (result) {
        Ok(:final value) when !value.isTrashed => value,
        _ => null,
      };
    });
  }

  Future<void> _onAction(_EntryAction action) async {
    switch (action) {
      case _EntryAction.edit:
        await openEntryEditor(context, editingId: widget.entryId);
        if (mounted) await _load();
      case _EntryAction.delete:
        await _delete();
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkDiaryEntryDeleteTitle,
      content: l10n.walkDiaryEntryDeleteContent,
      confirmLabel: l10n.walkDiaryEntryDelete,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final result = await getIt<DiaryUseCase>().trash(widget.entryId);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        AppSnackBar.show(
          context,
          message: l10n.walkDiaryEntryTrashed,
          type: AppSnackBarType.success,
        );
        Navigator.of(context).pop();
      case Err():
        AppSnackBar.show(
          context,
          message: l10n.walkDiaryEntryTrashFailed,
          type: AppSnackBarType.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = _entry;
    return Scaffold(
      appBar: AppBar(
        title: entry == null
            ? null
            : StreamBuilder<List<Story>>(
                stream: _stories,
                builder: (context, snapshot) {
                  final story = snapshot.data
                      ?.where((s) => s.id == entry.storyId)
                      .firstOrNull;
                  return Text(
                    story == null ? '' : storyDisplayTitle(l10n, story),
                  );
                },
              ),
        actions: [
          if (entry != null)
            AppOverflowMenu<_EntryAction>(
              enabled: !_busy,
              items: [
                AppOverflowMenuItem(
                  value: _EntryAction.edit,
                  label: l10n.walkDiaryEntryEdit,
                  icon: Icons.edit_outlined,
                ),
                AppOverflowMenuItem(
                  value: _EntryAction.delete,
                  label: l10n.walkDiaryEntryDelete,
                  icon: Icons.delete_outline,
                  isDestructive: true,
                ),
              ],
              onSelected: _onAction,
            ),
        ],
      ),
      body: switch ((_loading, entry)) {
        (true, _) => const SizedBox.shrink(),
        (false, null) => AppPlaceholder(
          icon: Icons.search_off,
          message: l10n.walkDiaryErrorNotFound,
        ),
        (false, final DiaryEntry entry) => _Body(
          entry: entry,
          videoBuilder: widget.videoBuilder,
        ),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.entry, required this.videoBuilder});

  final DiaryEntry entry;
  final VideoSurfaceBuilder videoBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = getIt<Clock>().now();
    final meta = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final place = entry.location?.placeName;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (entry.media.isNotEmpty)
          AspectRatio(
            aspectRatio: 1,
            child: MediaPager(
              media: entry.media,
              playing: true,
              fit: BoxFit.contain,
              videoBuilder: videoBuilder,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.walkDiaryEntryDateTime(
                  DiaryFormat.dateWithWeekday(l10n, entry.occurredAt, now),
                  DiaryFormat.time(context, entry.occurredAt),
                ),
                style: meta,
              ),
              if (place != null && place.isNotEmpty)
                Text(l10n.walkDiaryPlace(place), style: meta),
              if (entry.body.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(entry.body, style: theme.textTheme.bodyLarge),
              ],
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                EntryTags(tags: entry.tags),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
