import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../lock/widget/diary_lock_gate.dart';
import '../cubit/diary_timeline_cubit.dart';
import '../cubit/diary_timeline_state.dart';
import '../widget/diary_entries_view.dart';
import '../widget/story_bar.dart';
import '../widget/story_header.dart';

/// 셸의 일기 탭(스펙 §6.1). 위에서 `DiaryLockCubit` 를 받는다(셸이 소유).
///
/// 타임라인은 [DiaryLockGate] 안쪽에 있어 잠긴 동안 트리에 없다. 탭이 보이게 될 때마다
/// (처음부터 보이면 시작할 때) [DiaryUseCase.maintain] 을 부른다 — 기다리지 않고 실패는 삼킨다.
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

  @override
  void initState() {
    super.initState();
    if (widget.active) _maintain();
  }

  @override
  void didUpdateWidget(DiaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) _maintain();
  }

  @override
  void dispose() {
    _timeline.close();
    super.dispose();
  }

  /// 휴지통 기한 · 장소 이름 채우기. 화면을 막지 않는다 — 결과는 저장소 스트림으로 들어온다.
  void _maintain() => unawaited(_useCase.maintain().catchError((Object _) {}));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkShellTabDiary)),
      body: DiaryLockGate(
        child: BlocProvider.value(value: _timeline, child: const _Timeline()),
      ),
    );
  }
}

/// 스토리 바 + 고른 스토리의 머리 · 보기 모드 토글 + 기록.
class _Timeline extends StatelessWidget {
  const _Timeline();

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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StoryBar(
                open: state.openStories,
                archived: state.archived,
                selectedId: selectedId,
                onSelect: cubit.selectStory,
              ),
              const Divider(height: 1),
              StoryHeader(
                story: selected,
                now: getIt<Clock>().now(),
                mode: state.viewMode,
                onMode: cubit.setViewMode,
              ),
              Expanded(child: _Entries(state: state)),
            ],
          );
        },
      );
}

/// 기록 목록을 고른 보기 모드로. 읽지 못했으면 오류 안내, 비었으면 빈 상태 안내.
class _Entries extends StatelessWidget {
  const _Entries({required this.state});

  final DiaryTimelineState state;

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
      storyTitles: {
        for (final s in [...state.openStories, ...state.archived])
          s.id: storyDisplayTitle(l10n, s),
      },
      // 기록 상세(T15)가 생기면 여기서 연다.
      onOpen: (_) {},
    );
  }
}
