import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/media_limits.dart';
import '../../../domain/diary/entity/story.dart';
import '../../../domain/diary/location/place_source.dart';
import '../../../domain/diary/media/media_store.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../cubit/entry_editor_cubit.dart';
import '../cubit/entry_editor_state.dart';
import '../format/diary_format.dart';
import '../media_picker.dart';
import '../widget/media_strip.dart';
import '../widget/place_input.dart';
import '../widget/story_bar.dart';
import '../widget/story_picker_sheet.dart';
import '../widget/tag_chip_input.dart';
import '../widget/time_row.dart';

/// 기록 작성 · 수정(스펙 §6.2). [editingId] 가 있으면 그 기록을 고친다.
///
/// 저장하면 닫힌다. 바꾼 것이 있는데 닫으면(✕ · 뒤로) 버릴지 묻고, 버리면 새로 가져온
/// 임시 사본을 지운다.
class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({this.editingId, super.key});

  final String? editingId;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  final _repo = getIt<DiaryRepository>();
  final _picker = getIt<MediaPicker>();
  late final _cubit = EntryEditorCubit(
    getIt<DiaryUseCase>(),
    _repo,
    getIt<MediaStore>(),
    getIt<PlaceSource>(),
    getIt<Clock>(),
  );
  final _body = TextEditingController();

  /// 본문 입력칸을 채운 기록 id.
  String? _bodyFilledFor;

  /// 앨범 · 카메라가 열려 있는 동안 다시 열지 않는다.
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final id = widget.editingId;
    unawaited(id == null ? _cubit.startNew() : _cubit.startEdit(id));
  }

  @override
  void dispose() {
    _body.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _close() async {
    if (_cubit.state.saving) return;
    if (_cubit.hasChanges) {
      final l10n = AppLocalizations.of(context);
      final discard = await AppConfirmDialog.show(
        context,
        title: l10n.walkDiaryEditorDiscardTitle,
        content: l10n.walkDiaryEditorDiscardContent,
        confirmLabel: l10n.walkDiaryEditorDiscardConfirm,
      );
      if (!discard) return;
    }
    await _cubit.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addMedia(MediaSource source) async {
    if (_picking) return;
    _picking = true;
    try {
      final left = MediaLimits.maxItems - _cubit.state.draft.media.length;
      if (left <= 0) return;
      final picked = await switch (source) {
        MediaSource.gallery => _picker.pickGallery(limit: left),
        MediaSource.photo => _picker.takePhoto(),
        MediaSource.video => _picker.recordVideo(),
      };
      await _cubit.addMedia(picked);
    } catch (_) {
      // 권한 거부 · 카메라 없음 등 — 가져오지 못한 것으로 알린다.
      if (mounted) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).walkDiaryErrorMediaProcessing,
          type: AppSnackBarType.error,
        );
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _pickStory(EntryEditorState state) async {
    final id = await StoryPickerSheet.show(
      context,
      stories: state.openStories,
      selectedId: state.draft.storyId,
    );
    if (id != null) _cubit.setStory(id);
  }

  void _onState(BuildContext context, EntryEditorState state) {
    // 고치기: 기록을 읽어 오면 본문 입력칸을 채운다.
    if (state.isEditing && _bodyFilledFor != state.editingId) {
      _bodyFilledFor = state.editingId;
      _body.text = state.draft.body;
    }
    if (state.saved) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final message = switch (state) {
      EntryEditorState(:final error?) => DiaryFormat.failure(l10n, error),
      EntryEditorState(failed: true) => l10n.walkDiaryErrorSave,
      _ => null,
    };
    if (message != null) {
      AppSnackBar.show(context, message: message, type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<EntryEditorCubit, EntryEditorState>(
        listenWhen: (a, b) =>
            a.editingId != b.editingId ||
            (!a.saved && b.saved) ||
            (a.error == null && b.error != null) ||
            (!a.failed && b.failed),
        listener: _onState,
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) unawaited(_close());
            },
            child: Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.walkDiaryEditorClose,
                  onPressed: _close,
                ),
                title: Text(
                  state.isEditing
                      ? l10n.walkDiaryEditorEditTitle
                      : l10n.walkDiaryEditorNewTitle,
                ),
                actions: [
                  AppButton.text(
                    // 앱 테마 버튼은 폭을 가득 채운다(`Size.fromHeight`) — 폭이 정해지지 않은 자리라 최소 크기만 푼다.
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size.zero),
                    ),
                    label: state.isEditing
                        ? l10n.walkDiaryEditorSave
                        : l10n.walkDiaryEditorPost,
                    onPressed: state.saving || state.importing
                        ? null
                        : _cubit.save,
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                children: [
                  TimeRow(
                    occurredAt: state.draft.occurredAt,
                    createdAt: state.createdAt,
                    isEditing: state.isEditing,
                    now: getIt<Clock>().now(),
                    onPick: _cubit.setTime,
                    onRevert: _cubit.revertTime,
                  ),
                  PlaceInput(
                    location: state.draft.location,
                    locating: state.locating,
                    manualPlace: state.manualPlace,
                    onClear: _cubit.clearLocation,
                    onName: _cubit.setPlaceName,
                    suggestionsFor: (q) => _repo.watchPlaceCounts(query: q),
                  ),
                  AppListTile(
                    leading: const Icon(Icons.auto_stories_outlined),
                    title: Text(
                      l10n.walkDiaryEditorStory(_storyTitle(l10n, state)),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickStory(state),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MediaStrip(
                    media: state.draft.media,
                    importing: state.importing,
                    onAdd: _addMedia,
                    onRemove: _cubit.removeMedia,
                    onReorder: _cubit.reorderMedia,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _body,
                      minLines: 5,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: l10n.walkDiaryEditorBodyHint,
                      ),
                      onChanged: _cubit.setBody,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: TagChipInput(
                      tags: state.draft.tags,
                      onAdd: _cubit.addTag,
                      onRemove: _cubit.removeTag,
                      suggestionsFor: (q) => _repo.watchTagCounts(query: q),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 고친 기록이 닫힌 스토리에 있어도 이름을 보인다. 목록이 아직 없으면 '일상' 이름.
  static String _storyTitle(AppLocalizations l10n, EntryEditorState state) {
    final story = state.stories
        .where((s) => s.id == state.draft.storyId)
        .firstOrNull;
    return story == null
        ? (state.draft.storyId == Story.dailyId
              ? l10n.walkDiaryDailyStoryTitle
              : '')
        : storyDisplayTitle(l10n, story);
  }
}
