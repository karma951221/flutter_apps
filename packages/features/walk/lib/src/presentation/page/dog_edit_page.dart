import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../cubit/dog_edit_cubit.dart';
import '../cubit/dog_edit_state.dart';
import '../cubit/dog_form.dart';

class DogEditPage extends StatelessWidget {
  const DogEditPage({this.dogId, required this.onDone, super.key});

  /// null 이면 새 반려견을 등록한다.
  final String? dogId;

  /// 저장 또는 삭제가 끝났을 때 한 번 불린다.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<DogEditCubit>()..load(dogId),
    child: _DogEditView(isEdit: dogId != null, onDone: onDone),
  );
}

enum _DogMenuAction { delete }

class _DogEditView extends StatefulWidget {
  const _DogEditView({required this.isEdit, required this.onDone});

  final bool isEdit;
  final VoidCallback onDone;

  @override
  State<_DogEditView> createState() => _DogEditViewState();
}

class _DogEditViewState extends State<_DogEditView> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  bool _populated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  void _populate(DogForm form) {
    if (_populated) return;
    _populated = true;
    _nameController.text = form.name;
    _breedController.text = form.breed;
  }

  Future<void> _pickPhoto(DogEditCubit cubit) async {
    final picker = getIt<ImagePickerService>();
    final file = await picker.pickImage();
    if (file == null || !mounted) return;

    try {
      final prepared = await picker.prepare(file);
      if (!mounted) return;
      await cubit.setPhoto(prepared);
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

  Future<void> _pickBirthday(DogEditCubit cubit, DogForm form) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = form.birthday ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    cubit.setBirthday(DateUtils.dateOnly(picked));
  }

  Future<void> _confirmDelete(DogEditCubit cubit) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkDogDeleteConfirmTitle,
      content: l10n.walkDogDeleteConfirmMessage,
      confirmLabel: l10n.commonDelete,
    );
    if (!confirmed || !mounted) return;
    await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<DogEditCubit>();

    return BlocConsumer<DogEditCubit, DogEditState>(
      listenWhen: (previous, current) => switch (current) {
        DogEditSaved() || DogEditDeleted() => true,
        DogEditEditing(:final failure?) => switch (previous) {
          DogEditEditing(failure: final before) => before != failure,
          _ => true,
        },
        _ => false,
      },
      listener: (context, state) {
        switch (state) {
          case DogEditSaved() || DogEditDeleted():
            widget.onDone();
          case DogEditEditing(:final failure?):
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
        final form = switch (state) {
          DogEditEditing(:final form) => form,
          _ => null,
        };
        if (form != null) _populate(form);
        final isEdit = widget.isEdit;
        final isSaving = state is DogEditEditing && state.isSaving;

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? l10n.walkDogEditTitle : l10n.walkDogNewTitle),
            actions: [
              if (isEdit)
                AppOverflowMenu<_DogMenuAction>(
                  key: const Key('walk-dog-menu'),
                  enabled: !isSaving,
                  items: [
                    AppOverflowMenuItem(
                      value: _DogMenuAction.delete,
                      label: l10n.walkDogDeleteAction,
                      icon: Icons.delete_outline,
                      isDestructive: true,
                    ),
                  ],
                  onSelected: (_) => _confirmDelete(cubit),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              DogEditLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              // 곧 onDone 으로 화면을 떠난다.
              DogEditSaved() || DogEditDeleted() => const SizedBox.shrink(),
              DogEditLoadFailure(:final failure) => Center(
                child: AppPlaceholder(
                  message: failure.localizedMessage(context),
                ),
              ),
              DogEditEditing(:final form, :final isSaving) => _Form(
                form: form,
                isSaving: isSaving,
                nameController: _nameController,
                breedController: _breedController,
                onPickPhoto: () => _pickPhoto(cubit),
                onPickBirthday: () => _pickBirthday(cubit, form),
              ),
            },
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
    required this.nameController,
    required this.breedController,
    required this.onPickPhoto,
    required this.onPickBirthday,
  });

  final DogForm form;
  final bool isSaving;
  final TextEditingController nameController;
  final TextEditingController breedController;
  final VoidCallback onPickPhoto;
  final VoidCallback onPickBirthday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<DogEditCubit>();
    final photoPath = form.photoPath;
    final birthday = form.birthday;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(
          child: AppAvatar(
            nickname: form.name,
            radius: AppSpacing.xl * 2,
            imageFile: photoPath == null ? null : cubit.photoFile(photoPath),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: AppButton.text(
            key: const Key('walk-dog-photo-button'),
            label: l10n.walkDogPhotoChange,
            onPressed: isSaving ? null : onPickPhoto,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('walk-dog-name-field'),
          controller: nameController,
          enabled: !isSaving,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.walkDogNameLabel),
          onChanged: cubit.setName,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('walk-dog-breed-field'),
          controller: breedController,
          enabled: !isSaving,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: l10n.walkDogBreedLabel),
          onChanged: cubit.setBreed,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppListTile(
          key: const Key('walk-dog-birthday-tile'),
          title: Text(l10n.walkDogBirthdayLabel),
          subtitle: Text(
            birthday == null
                ? l10n.walkDogBirthdayUnset
                : MaterialLocalizations.of(context).formatMediumDate(birthday),
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          enabled: !isSaving,
          onTap: onPickBirthday,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          key: const Key('walk-dog-save-button'),
          label: l10n.walkDogSaveAction,
          isLoading: isSaving,
          onPressed: cubit.save,
        ),
      ],
    );
  }
}
