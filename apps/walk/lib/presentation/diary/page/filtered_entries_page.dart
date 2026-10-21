import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_view_mode.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../cubit/filtered_entries_cubit.dart';
import '../cubit/filtered_entries_state.dart';
import '../../theme/walk_theme.dart';
import '../widget/diary_entries_view.dart';
import '../widget/story_bar.dart';
import '../widget/view_mode_switch.dart';
import 'diary_route.dart';
import 'entry_detail_page.dart';

/// 태그 · 장소 모아보기를 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openFilteredEntries(BuildContext context, EntryFilter filter) =>
    pushDiaryRoute<void>(
      context,
      page: (_) => FilteredEntriesPage(filter: filter),
    );

/// 태그 · 장소 모아보기(스펙 §6.4): 스토리를 넘나들며 [filter] 의 기록을 보기 모드 3종으로.
/// 열린 채로 기록이 추가 · 휴지통 · 복원되면 바로 따라간다. 릴스에서는 일기 탭처럼 기록이 화면을
/// 채우고, 앱바 · 개수 · 토글을 어두운 반투명 바탕으로 위에 얹는다.
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
    getIt<DiaryPreferences>(),
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

  /// 릴스 위 앱바 바탕의 불투명도 — 일기 탭 머리와 같다.
  static const _overlayAlpha = 0.7;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FilteredEntriesCubit, FilteredEntriesState>(
        bloc: _cubit,
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final reels = state.viewMode == DiaryViewMode.reels;
          final countBar = Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.loading || state.failed
                        ? ''
                        : l10n.walkDiaryEntryCount(state.entries.length),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                ViewModeSwitch(
                  mode: state.viewMode,
                  onChanged: _cubit.setViewMode,
                ),
              ],
            ),
          );
          if (!reels) {
            return Scaffold(
              appBar: AppBar(title: Text(_title(l10n))),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  countBar,
                  Expanded(child: _Body(state: state)),
                ],
              ),
            );
          }
          final body = _Body(state: state);
          return Theme(
            data: WalkTheme.dark(),
            child: Builder(
              builder: (context) {
                final overlay = Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: _overlayAlpha);
                return Scaffold(
                  extendBodyBehindAppBar: true,
                  appBar: AppBar(
                    title: Text(_title(l10n)),
                    backgroundColor: overlay,
                    // 기록이 앱바 밑을 지나가도 색이 바뀌지 않게.
                    scrolledUnderElevation: 0,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(
                        kMinInteractiveDimension + AppSpacing.sm * 2,
                      ),
                      child: countBar,
                    ),
                  ),
                  body: body,
                );
              },
            ),
          );
        },
      );
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final FilteredEntriesState state;

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
    if (state.entries.isEmpty) {
      return AppPlaceholder(
        icon: Icons.menu_book_outlined,
        message: l10n.walkDiaryCollectionEmpty,
      );
    }
    return DiaryEntriesView(
      mode: state.viewMode,
      entries: state.entries,
      // 스토리를 넘나들므로 기록마다 스토리 이름을 붙인다.
      showStoryName: true,
      storyTitles: {
        for (final s in state.stories) s.id: storyDisplayTitle(l10n, s),
      },
      onOpen: (entry) => openEntryDetail(context, entry.id),
    );
  }
}
