import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../cubit/walk_edit_cubit.dart';
import '../cubit/walk_edit_form.dart';
import '../cubit/walk_edit_state.dart';
import '../widget/dog_chips.dart';
import '../widget/photo_source_sheet.dart';
import '../widget/photo_strip.dart';
import '../widget/walk_stats_row.dart';

/// 산책 저장(신규) · 수정 화면.
///
/// [walkId] 가 null 이면 방금 끝난 추적 세션을 저장하는 신규 모드, 아니면 저장된
/// 산책의 강아지 · 메모 · 사진을 고치는 수정 모드다. 라우팅은 모른다 —
/// 저장하면 [onSaved], 신규에서 버리면 [onDiscarded] 가 한 번 불린다.
class WalkEditPage extends StatelessWidget {
  const WalkEditPage({
    this.walkId,
    required this.onSaved,
    required this.onDiscarded,
    super.key,
  });

  final String? walkId;
  final ValueChanged<String> onSaved;
  final VoidCallback onDiscarded;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = getIt<WalkEditCubit>();
      final id = walkId;
      if (id == null) {
        cubit.loadNew();
      } else {
        cubit.loadExisting(id);
      }
      return cubit;
    },
    child: _WalkEditView(
      isNew: walkId == null,
      onSaved: onSaved,
      onDiscarded: onDiscarded,
    ),
  );
}

class _WalkEditView extends StatefulWidget {
  const _WalkEditView({
    required this.isNew,
    required this.onSaved,
    required this.onDiscarded,
  });

  final bool isNew;
  final ValueChanged<String> onSaved;
  final VoidCallback onDiscarded;

  @override
  State<_WalkEditView> createState() => _WalkEditViewState();
}

class _WalkEditViewState extends State<_WalkEditView> {
  final _memoController = TextEditingController();
  bool _populated = false;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _populate(WalkEditForm form) {
    if (_populated) return;
    _populated = true;
    _memoController.text = form.memo;
  }

  Future<void> _confirmDiscard() async {
    final cubit = context.read<WalkEditCubit>();
    final state = cubit.state;
    if (state is! WalkEditEditing || state.isSaving) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkDiscardConfirmTitle,
      content: l10n.walkDiscardConfirmMessage,
      confirmLabel: l10n.walkDiscard,
    );
    if (!confirmed || cubit.isClosed) return;
    await cubit.discard();
  }

  Future<void> _addPhoto(WalkEditCubit cubit) async {
    final source = await PhotoSourceSheet.show(context);
    if (source == null || !mounted) return;

    final current = cubit.state;
    if (current is! WalkEditEditing) return;
    final room = WalkEditForm.maxPhotos - current.form.photoPaths.length;
    if (room <= 0) return;

    try {
      final picker = getIt<ImagePickerService>();
      final images = switch (source) {
        PhotoSource.gallery => await picker.pickImages(limit: room),
        PhotoSource.camera => [?await picker.captureImage()],
      };
      if (images.isEmpty || !mounted) return;
      await cubit.addPhotos(images);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: const Failure.unknown(
          failureCode: FailureCode.walkPhotoSaveFailed,
        ).localizedMessage(context),
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<WalkEditCubit>();

    return BlocConsumer<WalkEditCubit, WalkEditState>(
      listenWhen: (previous, current) => switch (current) {
        WalkEditSaved() || WalkEditDiscarded() => true,
        WalkEditEditing(:final failure?) => switch (previous) {
          WalkEditEditing(failure: final before) => before != failure,
          _ => true,
        },
        _ => false,
      },
      listener: (context, state) {
        switch (state) {
          case WalkEditSaved(:final walkId):
            widget.onSaved(walkId);
          case WalkEditDiscarded():
            widget.onDiscarded();
          case WalkEditEditing(:final failure?):
            AppSnackBar.show(
              context,
              message: failure.localizedMessage(context),
              type: AppSnackBarType.error,
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        if (state case WalkEditEditing(:final form)) _populate(form);

        // 신규에서 그냥 나가면 `finished` 세션이 남아 새 산책을 막는다 — 버리기와 같은 확인을 거친다.
        final guardBack = widget.isNew && state is WalkEditEditing;

        return PopScope(
          canPop: !guardBack,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isNew ? l10n.walkEditNewTitle : l10n.walkEditTitle,
              ),
            ),
            body: SafeArea(
              child: switch (state) {
                WalkEditLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                // 곧 onSaved · onDiscarded 로 화면을 떠난다.
                WalkEditSaved() ||
                WalkEditDiscarded() => const SizedBox.shrink(),
                WalkEditLoadFailure(:final failure) => Center(
                  child: widget.isNew
                      ? AppPlaceholder(
                          key: const Key('walk-edit-no-session'),
                          message: l10n.walkNoSessionToSave,
                          actionLabel: l10n.walkBackToFeed,
                          onAction: widget.onDiscarded,
                        )
                      : AppPlaceholder(
                          message: failure.localizedMessage(context),
                        ),
                ),
                WalkEditEditing(:final form, :final isSaving) => _Form(
                  form: form,
                  isSaving: isSaving,
                  memoController: _memoController,
                  onAddPhoto: () => _addPhoto(cubit),
                  onDiscard: _confirmDiscard,
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.form,
    required this.isSaving,
    required this.memoController,
    required this.onAddPhoto,
    required this.onDiscard,
  });

  final WalkEditForm form;
  final bool isSaving;
  final TextEditingController memoController;
  final VoidCallback onAddPhoto;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<WalkEditCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          form.startedAt.displayDateTime(l10n.localeName),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        WalkStatsRow(
          distanceMeters: form.distanceMeters,
          elapsed: form.duration,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.walkSelectDogs, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        IgnorePointer(
          ignoring: isSaving,
          child: DogChips(
            keyPrefix: 'walk-edit-dog-chip',
            dogs: form.dogs,
            selectedIds: form.selectedDogIds,
            onToggle: cubit.toggleDog,
            photoFile: cubit.photoFile,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('walk-edit-memo-field'),
          controller: memoController,
          enabled: !isSaving,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: l10n.walkMemoLabel,
            hintText: l10n.walkMemoHint,
            alignLabelWithHint: true,
          ),
          onChanged: cubit.setMemo,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.walkPhotosLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        PhotoStrip(
          photoPaths: form.photoPaths,
          photoFile: cubit.photoFile,
          maxPhotos: WalkEditForm.maxPhotos,
          enabled: !isSaving,
          onAdd: onAddPhoto,
          onRemove: cubit.removePhoto,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          key: const Key('walk-edit-save-button'),
          label: l10n.commonSave,
          isLoading: isSaving,
          onPressed: cubit.save,
        ),
        if (form.isNew) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton.text(
            key: const Key('walk-edit-discard-button'),
            label: l10n.walkDiscard,
            onPressed: isSaving ? null : onDiscard,
          ),
        ],
      ],
    );
  }
}
