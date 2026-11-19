import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../cubit/trash_cubit.dart';
import '../cubit/trash_state.dart';
import '../format/diary_format.dart';
import '../widget/entry_media_view.dart';
import 'diary_route.dart';

/// 휴지통을 연다. 일기 잠금에 묶인 화면([pushDiaryRoute])이라 다시 잠기면 가려진다.
Future<void> openTrash(BuildContext context) =>
    pushDiaryRoute<void>(context, page: (_) => const TrashPage());

enum _TrashAction { restore, purge }

/// 휴지통(스펙 §5.1 · §6.5): 지운 기록과 영구 삭제까지 남은 일수, 복원 · 영구 삭제 · 비우기.
///
/// 앱바는 화면 전체 동작(비우기)만 둔다. 행 동작(복원 · 영구 삭제)은 행을 누르거나 길게
/// 누르면 뜨는 시트에 있다 — 앱바와 행에 ⋮ 가 겹치지 않게.
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  late final _cubit = TrashCubit(
    getIt<DiaryRepository>(),
    getIt<DiaryUseCase>(),
    getIt<DiaryPreferences>(),
    getIt<Clock>(),
  )..start();

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  /// 동작을 기다린 뒤 성공이면 [success] 를, 실패면 [failure] 를 알린다.
  Future<void> _run(
    Future<void> action, {
    required String success,
    required String failure,
  }) async {
    await action;
    if (!mounted) return;
    final failed = _cubit.state.actionFailed;
    AppSnackBar.show(
      context,
      message: failed ? failure : success,
      type: failed ? AppSnackBarType.error : AppSnackBarType.success,
    );
  }

  Future<void> _onAction(String id, _TrashAction action) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _TrashAction.restore:
        await _run(
          _cubit.restore(id),
          success: l10n.walkDiaryTrashRestored,
          failure: l10n.walkDiaryTrashRestoreFailed,
        );
      case _TrashAction.purge:
        final confirmed = await AppConfirmDialog.show(
          context,
          title: l10n.walkDiaryTrashPurgeTitle,
          content: l10n.walkDiaryTrashPurgeContent,
          confirmLabel: l10n.walkDiaryTrashDeleteForever,
        );
        if (!confirmed || !mounted) return;
        await _run(
          _cubit.purge(id),
          success: l10n.walkDiaryTrashPurged,
          failure: l10n.walkDiaryTrashDeleteFailed,
        );
    }
  }

  /// 행 동작 시트 — 제목은 그 기록의 첫 줄, 영구 삭제는 error 색.
  Future<void> _openActions(TrashItem item) async {
    final l10n = AppLocalizations.of(context);
    final action = await showAppSheet<_TrashAction>(
      context: context,
      builder: (context) {
        final error = Theme.of(context).colorScheme.error;
        return AppSheetScaffold(
          title: _rowTitle(l10n, item.entry),
          children: [
            AppListTile(
              key: const Key('trash-action-restore'),
              leading: const Icon(Icons.restore_from_trash_outlined),
              title: Text(l10n.walkDiaryTrashRestore),
              onTap: () => Navigator.pop(context, _TrashAction.restore),
            ),
            AppListTile(
              key: const Key('trash-action-purge'),
              leading: Icon(Icons.delete_forever_outlined, color: error),
              title: Text(
                l10n.walkDiaryTrashDeleteForever,
                style: TextStyle(color: error),
              ),
              onTap: () => Navigator.pop(context, _TrashAction.purge),
            ),
          ],
        );
      },
    );
    if (action == null || !mounted) return;
    await _onAction(item.entry.id, action);
  }

  /// 시트 제목 — 본문 첫 줄(길면 줄임). 본문이 없으면 '글 없음' 안내.
  static String _rowTitle(AppLocalizations l10n, DiaryEntry entry) {
    final body = entry.body.trim();
    if (body.isEmpty) return l10n.walkDiaryTrashNoBody;
    final line = body.split('\n').first.trim();
    return line.characters.length <= _titleMax
        ? line
        : '${line.characters.take(_titleMax)}…';
  }

  /// 시트 제목 최대 글자 수.
  static const _titleMax = 40;

  Future<void> _emptyAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkDiaryTrashEmptyAllTitle,
      content: l10n.walkDiaryTrashEmptyAllContent(_cubit.state.items.length),
      confirmLabel: l10n.walkDiaryTrashEmptyAll,
    );
    if (!confirmed || !mounted) return;
    await _run(
      _cubit.emptyAll(),
      success: l10n.walkDiaryTrashEmptied,
      failure: l10n.walkDiaryTrashDeleteFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TrashCubit, TrashState>(
      bloc: _cubit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.walkDiaryMenuTrash),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.walkDiaryTrashEmptyAll,
              onPressed: state.items.isEmpty ? null : _emptyAll,
            ),
          ],
        ),
        body: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, TrashState state) {
    final l10n = AppLocalizations.of(context);
    if (state.failed) {
      return AppPlaceholder(
        icon: Icons.error_outline,
        message: l10n.walkDiaryLoadError,
      );
    }
    if (state.loading) return const AppLoading(delayed: true);
    if (state.items.isEmpty) {
      return AppPlaceholder(
        icon: Icons.delete_outline,
        message: l10n.walkDiaryTrashEmpty,
      );
    }
    final now = getIt<Clock>().now();
    return ListView(
      children: [
        for (final item in state.items)
          GestureDetector(
            key: ValueKey(item.entry.id),
            onLongPress: () => unawaited(_openActions(item)),
            child: AppListTile(
              leading: _TrashThumb(entry: item.entry),
              title: Text(
                item.entry.body.trim().isEmpty
                    ? l10n.walkDiaryTrashNoBody
                    : item.entry.body.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_subtitle(l10n, item, now)),
              onTap: () => unawaited(_openActions(item)),
            ),
          ),
      ],
    );
  }

  /// `10월 7일` + 남은 일수(안 함이면 날짜만).
  String _subtitle(AppLocalizations l10n, TrashItem item, DateTime now) {
    final date = DiaryFormat.date(l10n, item.entry.occurredAt, now);
    final left = item.daysLeft;
    if (left == null) return date;
    final label = left == 0
        ? l10n.walkDiaryTrashDueToday
        : l10n.walkDiaryTrashDaysLeft(left);
    return '$date · $label';
  }
}

/// 휴지통 행 앞의 첫 미디어 썸네일(영상은 썸네일 + 재생 표시). 미디어가 없으면 글 아이콘.
class _TrashThumb extends StatelessWidget {
  const _TrashThumb({required this.entry});

  final DiaryEntry entry;

  /// 썸네일 한 변. 시각 토큰이 아니라 이 행의 크기다.
  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final first = entry.media.firstOrNull;
    return SizedBox.square(
      dimension: _size,
      child: first == null
          ? const Icon(Icons.notes_outlined)
          : ClipRRect(
              borderRadius: AppRadius.smAll,
              child: EntryMediaView(media: first),
            ),
    );
  }
}
