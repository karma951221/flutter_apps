import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../cubit/filtered_entries_cubit.dart';
import '../cubit/filtered_entries_state.dart';
import '../viewer/story_viewer_page.dart';
import '../widget/entry_grid.dart';
import 'diary_route.dart';

/// 태그 · 장소 모아보기를 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openFilteredEntries(BuildContext context, EntryFilter filter) =>
    pushDiaryRoute<void>(
      context,
      page: (_) => FilteredEntriesPage(filter: filter),
    );

/// 태그 · 장소 모아보기(스펙 §3.5): 스토리를 넘나들며 [filter] 의 기록을 `기록 n개` · `▶ 보기` ·
/// 3열 그리드로. `▶ 보기` 는 모아보기 소스 뷰어를 처음부터, 칸은 그 기록부터 연다.
/// 열린 채로 기록이 추가 · 휴지통 · 복원되면 바로 따라간다.
class FilteredEntriesPage extends StatefulWidget {
  const FilteredEntriesPage({required this.filter, super.key});

  /// [EntryFilter.tag] 또는 [EntryFilter.place].
  final EntryFilter filter;

  @override
  State<FilteredEntriesPage> createState() => _FilteredEntriesPageState();
}

class _FilteredEntriesPageState extends State<FilteredEntriesPage> {
  late final _cubit = FilteredEntriesCubit(
    getIt<DiaryRepository>(),
    widget.filter,
  )..start();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  String _title(AppLocalizations l10n) => switch (widget.filter) {
    TagEntries(:final name) => l10n.walkDiaryTag(name),
    PlaceEntries(:final name) => l10n.walkDiaryPlace(name),
    // 모아보기는 태그 · 장소만 연다. 다른 필터는 이름표 없이.
    _ => '',
  };

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FilteredEntriesCubit, FilteredEntriesState>(
        bloc: _cubit,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            appBar: AppBar(title: Text(_title(l10n))),
            body: _body(context, state, l10n),
          );
        },
      );

  Widget _body(
    BuildContext context,
    FilteredEntriesState state,
    AppLocalizations l10n,
  ) {
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
        message: l10n.walkDiaryCollectionEmpty,
      );
    }
    // 뷰어 소스 이름은 앱바 제목과 같다.
    final source = ViewerSource.filter(widget.filter, _title(l10n));
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.walkDiaryEntryCount(state.entries.length),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(
                  label: l10n.walkDiaryPlay,
                  onPressed: () =>
                      openStoryViewer(context, source, fromStart: true),
                ),
              ],
            ),
          ),
        ),
        SliverEntryGrid(
          entries: state.entries,
          onOpen: (entry) =>
              openStoryViewer(context, source, entryId: entry.id),
        ),
      ],
    );
  }
}
