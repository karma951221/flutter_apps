import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/diary/usecase/story_order.dart';
import '../widget/story_avatar.dart';
import '../widget/story_picker_sheet.dart';
import 'entry_editor_page.dart';

/// 기록 ⋮ 메뉴의 동작(수정 · 스토리 옮기기 · 휴지통). 스토리 뷰어 · 피드가 함께 쓴다.

/// 그 기록의 고치기 화면을 열고, 닫히면 끝난다.
Future<void> editEntry(BuildContext context, DiaryEntry entry) =>
    openEntryEditor(context, editingId: entry.id);

/// 스토리를 골라(진행 중 → 지난 스토리 순) 옮긴다. 닫힌 스토리로도 옮길 수 있다(R23).
/// 옮겼으면 되돌리기 스낵바를 띄우고 true. 고르지 않았거나 같은 스토리 · 실패면 false.
Future<bool> moveEntry(BuildContext context, DiaryEntry entry) async {
  final repo = getIt<DiaryRepository>();
  final l10n = AppLocalizations.of(context);
  final List<Story> all;
  try {
    all = await repo.watchStories().first;
  } on Object {
    return false;
  }
  if (!context.mounted) return false;
  final order = StoryOrder.split(all);
  final stories = [...order.open, ...order.archived];
  final picked = await StoryPickerSheet.show(
    context,
    stories: stories,
    selectedId: entry.storyId,
  );
  if (picked == null || picked == entry.storyId || !context.mounted) {
    return false;
  }
  final result = await repo.moveEntries([entry.id], picked);
  if (!context.mounted) return result is Ok;
  switch (result) {
    case Ok():
      final story = stories.firstWhere((s) => s.id == picked);
      final from = entry.storyId;
      AppSnackBar.show(
        context,
        message: l10n.walkDiaryEntryMoved(storyDisplayTitle(l10n, story)),
        type: AppSnackBarType.success,
        actionLabel: l10n.walkDiaryUndo,
        onAction: () => repo.moveEntries([entry.id], from),
      );
      return true;
    case Err():
      AppSnackBar.show(
        context,
        message: l10n.walkDiaryEntryMoveFailed,
        type: AppSnackBarType.error,
      );
      return false;
  }
}

/// 휴지통으로 보낸다([confirm] 이면 먼저 확인을 받는다 — 뷰어는 되돌리기가 있어 묻지 않는다).
/// 보냈으면 되돌리기(복원) 스낵바를 띄우고 true. 취소 · 실패면 false(실패는 오류 스낵바).
Future<bool> trashEntry(
  BuildContext context,
  DiaryEntry entry, {
  bool confirm = true,
}) async {
  final l10n = AppLocalizations.of(context);
  if (confirm) {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkDiaryEntryDeleteTitle,
      content: l10n.walkDiaryEntryDeleteContent,
      confirmLabel: l10n.walkDiaryEntryDelete,
    );
    if (!confirmed || !context.mounted) return false;
  }
  final useCase = getIt<DiaryUseCase>();
  final result = await useCase.trash(entry.id);
  if (!context.mounted) return result is Ok;
  switch (result) {
    case Ok():
      AppSnackBar.show(
        context,
        message: l10n.walkDiaryEntryTrashed,
        type: AppSnackBarType.success,
        actionLabel: l10n.walkDiaryUndo,
        onAction: () => useCase.restore(entry.id),
      );
      return true;
    case Err():
      AppSnackBar.show(
        context,
        message: l10n.walkDiaryEntryTrashFailed,
        type: AppSnackBarType.error,
      );
      return false;
  }
}
