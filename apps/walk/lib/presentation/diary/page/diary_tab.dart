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
import '../widget/story_bar.dart';

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

/// 스토리 바 + 고른 스토리의 기록.
class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DiaryTimelineCubit, DiaryTimelineState>(
        builder: (context, state) {
          final cubit = context.read<DiaryTimelineCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StoryBar(
                open: state.openStories,
                archived: state.archived,
                selectedId: state.selectedStoryId,
                onSelect: cubit.selectStory,
              ),
              const Divider(height: 1),
              Expanded(child: _Entries(state: state)),
            ],
          );
        },
      );
}

/// 기록 목록. 보기 모드(줄글 · 피드 · 릴스)는 T13 이 이 자리를 바꾼다 — 지금은 본문만 보인다.
class _Entries extends StatelessWidget {
  const _Entries({required this.state});

  final DiaryTimelineState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) return const SizedBox.shrink();
    final entries = state.entries;
    if (entries.isEmpty) {
      return AppPlaceholder(
        icon: Icons.menu_book_outlined,
        message: AppLocalizations.of(context).walkDiaryEmpty,
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) => AppListTile(title: Text(entries[i].body)),
    );
  }
}
