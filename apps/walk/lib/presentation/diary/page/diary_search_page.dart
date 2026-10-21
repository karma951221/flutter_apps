import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_filter.dart';
import '../../../domain/diary/entity/named_count.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../cubit/diary_search_cubit.dart';
import '../cubit/diary_search_state.dart';
import '../format/diary_format.dart';
import '../widget/highlighted_text.dart';
import '../viewer/story_viewer_page.dart';
import '../widget/story_avatar.dart';
import 'diary_route.dart';
import 'filtered_entries_page.dart';
import 'story_page.dart';

/// 일기 검색을 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openDiarySearch(BuildContext context) =>
    pushDiaryRoute<void>(context, page: (_) => const DiarySearchPage());

/// 일기 검색(스펙 §6.4): 입력칸 하나 + 탭 [글 · 스토리 · 해시태그 · 장소].
///
/// 글 결과는 그 기록부터 뷰어로, 스토리 결과는 스토리 페이지로, 해시태그 · 장소 추천은 모아보기를 연다.
class DiarySearchPage extends StatefulWidget {
  const DiarySearchPage({super.key});

  @override
  State<DiarySearchPage> createState() => _DiarySearchPageState();
}

class _DiarySearchPageState extends State<DiarySearchPage> {
  DiarySearchCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 기본 스토리를 찾을 이름이 l10n 에 있다 — 처음 한 번만 만든다.
    _cubit ??= DiarySearchCubit(
      getIt<DiaryRepository>(),
      dailyTitle: AppLocalizations.of(context).walkDiaryDailyStoryTitle,
    );
  }

  @override
  void dispose() {
    unawaited(_cubit?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = _cubit!;
    return BlocProvider.value(
      value: cubit,
      child: DefaultTabController(
        length: SearchScope.values.length,
        child: Scaffold(
          appBar: AppBar(
            title: TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.walkDiarySearchHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: cubit.setQuery,
            ),
            bottom: TabBar(
              // 탭 순서 = SearchScope 순서.
              onTap: (i) => cubit.setScope(SearchScope.values[i]),
              tabs: [
                for (final s in SearchScope.values)
                  Tab(
                    text: switch (s) {
                      SearchScope.body => l10n.walkDiarySearchTabBody,
                      SearchScope.story => l10n.walkDiarySearchTabStory,
                      SearchScope.tag => l10n.walkDiarySearchTabTag,
                      SearchScope.place => l10n.walkDiarySearchTabPlace,
                    },
                  ),
              ],
            ),
          ),
          body: BlocBuilder<DiarySearchCubit, DiarySearchState>(
            builder: (context, state) => _Results(state: state),
          ),
        ),
      ),
    );
  }
}

/// 지금 탭의 결과 · 안내.
class _Results extends StatelessWidget {
  const _Results({required this.state});

  final DiarySearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.failed) {
      return AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkDiaryLoadError,
      );
    }
    final term = state.query.trim();
    final prompt = switch (state.scope) {
      SearchScope.body => l10n.walkDiarySearchBodyPrompt,
      SearchScope.story => l10n.walkDiarySearchStoryPrompt,
      SearchScope.tag || SearchScope.place => null,
    };
    if (prompt != null && term.isEmpty) {
      return AppPlaceholder(icon: Icons.search, message: prompt);
    }
    final count = switch (state.scope) {
      SearchScope.body => state.bodyResults.length,
      SearchScope.story => state.stories.length,
      SearchScope.tag || SearchScope.place => state.suggestions.length,
    };
    if (count == 0) {
      // 아직 지금 입력의 결과가 오지 않았으면(디바운스 · 조회 중) 비워 둔다.
      if (state.loading || state.searched != term) {
        return const SizedBox.shrink();
      }
      return AppPlaceholder(
        icon: Icons.search_off,
        message: l10n.walkDiarySearchNoResults,
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: count,
      itemBuilder: (context, i) => switch (state.scope) {
        SearchScope.body => _BodyResult(
          entry: state.bodyResults[i],
          query: state.searched,
        ),
        SearchScope.story => AppListTile(
          leading: const Icon(Icons.auto_stories_outlined),
          title: Text(storyDisplayTitle(l10n, state.stories[i].story)),
          trailing: Text(l10n.walkDiaryEntryCount(state.stories[i].count)),
          onTap: () =>
              unawaited(openStoryPage(context, state.stories[i].story.id)),
        ),
        SearchScope.tag => _Suggestion(
          icon: Icons.tag,
          label: l10n.walkDiaryTag(state.suggestions[i].name),
          item: state.suggestions[i],
          filter: EntryFilter.tag(state.suggestions[i].name),
        ),
        SearchScope.place => _Suggestion(
          icon: Icons.place_outlined,
          label: state.suggestions[i].name,
          item: state.suggestions[i],
          filter: EntryFilter.place(state.suggestions[i].name),
        ),
      },
    );
  }
}

/// 본문 결과 한 줄: 일치 부분이 보이는 조각(강조) + 날짜 시각. 누르면 그 기록부터 뷰어.
class _BodyResult extends StatelessWidget {
  const _BodyResult({required this.entry, required this.query});

  final DiaryEntry entry;
  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final at = entry.occurredAt;
    return AppListTile(
      title: HighlightedText(
        matchSnippet(entry.body, query),
        query: query,
        maxLines: 2,
      ),
      subtitle: Text(
        l10n.walkDiaryEntryDateTime(
          DiaryFormat.date(l10n, at, getIt<Clock>().now()),
          DiaryFormat.time(context, at),
        ),
      ),
      onTap: () => unawaited(
        openStoryViewer(
          context,
          ViewerSource.stories([entry.storyId]),
          entryId: entry.id,
        ),
      ),
    );
  }
}

/// 해시태그 · 장소 추천 한 줄(쓴 기록 수). 누르면 그 모아보기.
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.label,
    required this.item,
    required this.filter,
  });

  final IconData icon;
  final String label;
  final NamedCount item;
  final EntryFilter filter;

  @override
  Widget build(BuildContext context) => AppListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(
      AppLocalizations.of(context).walkDiaryEntryCount(item.count),
    ),
    onTap: () => unawaited(openFilteredEntries(context, filter)),
  );
}
