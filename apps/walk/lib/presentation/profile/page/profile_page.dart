import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/profile/profile.dart';
import '../../diary/media_picker.dart';
import '../cubit/profile_cubit.dart';
import '../widget/profile_avatar.dart';

/// 프로필 편집 — 사진(앨범 · 카메라 · 지우기), 이름, 한 줄 소개, 물어보기에 이름 알려주기.
///
/// 바꾼 것은 앱바의 저장을 눌러야 저장된다. 바꾼 게 있는데 뒤로 가면 버릴지 묻는다.
/// 고른 사진의 picker 캐시 사본은 저장하거나 버린 뒤 지운다.
class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.picker, super.key});

  final MediaPicker picker;

  /// [context] 위의 [ProfileCubit] 을 새 라우트에 다시 건다. 저장하고 닫히면 [context] 에
  /// '저장했어요'를 띄운다.
  static Future<void> open(BuildContext context, {MediaPicker? picker}) async {
    final cubit = context.read<ProfileCubit>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ProfilePage(picker: picker ?? getIt<MediaPicker>()),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      AppSnackBar.success(
        context,
        message: AppLocalizations.of(context).walkProfileSaved,
      );
    }
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Profile _initial;
  late final String? _initialPhotoPath;
  late final _name = TextEditingController(text: _initial.name);
  late final _bio = TextEditingController(text: _initial.bio);
  late bool _shareName = _initial.shareNameWithAi;
  PhotoEdit _photo = const PhotoEdit.keep();

  /// picker 가 만든 캐시 사본 — 화면을 떠날 때 지운다.
  final _picked = <String>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    _initial = state.profile;
    _initialPhotoPath = state.photoPath;
    _name.addListener(_changed);
    _bio.addListener(_changed);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    unawaited(
      widget.picker.release([
        for (final path in _picked) (path: path, kind: MediaKind.photo),
      ]),
    );
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _dirty =>
      _photo is! PhotoKeep ||
      _name.text.trim() != _initial.name ||
      _bio.text.trim() != _initial.bio ||
      _shareName != _initial.shareNameWithAi;

  String? get _photoPath => switch (_photo) {
    PhotoKeep() => _initialPhotoPath,
    PhotoReplace(:final source) => source,
    PhotoRemove() => null,
  };

  Future<void> _choosePhoto() async {
    final l10n = AppLocalizations.of(context);
    final hasPhoto = _photoPath != null;
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, icon, label) in [
              (
                _PhotoChoice.gallery,
                Icons.photo_library_outlined,
                l10n.walkProfilePhotoGallery,
              ),
              (
                _PhotoChoice.camera,
                Icons.photo_camera_outlined,
                l10n.walkProfilePhotoCamera,
              ),
              if (hasPhoto)
                (
                  _PhotoChoice.remove,
                  Icons.delete_outline,
                  l10n.walkProfilePhotoRemove,
                ),
            ])
              AppListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(sheet, value),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == _PhotoChoice.remove) {
      setState(() => _photo = const PhotoEdit.remove());
      return;
    }
    final String? path;
    try {
      path = await widget.picker.pickProfilePhoto(
        camera: choice == _PhotoChoice.camera,
      );
    } on Object {
      if (mounted) {
        AppSnackBar.error(context, message: l10n.walkProfilePhotoFailed);
      }
      return;
    }
    if (path == null || !mounted) return;
    _picked.add(path);
    setState(() => _photo = PhotoEdit.replace(path!));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await context.read<ProfileCubit>().save(
        name: _name.text,
        bio: _bio.text,
        shareNameWithAi: _shareName,
        photo: _photo,
      );
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, message: l10n.walkProfileSaveFailed);
      return;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _maybePop() async {
    final l10n = AppLocalizations.of(context);
    final discard = await AppConfirmDialog.show(
      context,
      title: l10n.walkProfileDiscardTitle,
      content: l10n.walkProfileDiscardBody,
      confirmLabel: l10n.walkProfileDiscard,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_maybePop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.walkProfileTitle),
          actions: [
            AppButton.text(
              key: const Key('profile-save'),
              // 앱 테마 버튼은 폭을 가득 채운다(`Size.fromHeight`) — 앱바 자리라 최소 크기만 푼다.
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size.zero),
              ),
              label: l10n.commonSave,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            Center(
              child: Tooltip(
                message: l10n.walkProfilePhotoChange,
                child: InkWell(
                  key: const Key('profile-photo'),
                  customBorder: const CircleBorder(),
                  onTap: _saving ? null : _choosePhoto,
                  child: Stack(
                    children: [
                      ProfileAvatar(
                        name: _name.text,
                        photoPath: _photoPath,
                        radius: 48,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: AppSpacing.md,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(
                            Icons.photo_camera_outlined,
                            size: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  TextField(
                    key: const Key('profile-name'),
                    controller: _name,
                    maxLength: Profile.maxName,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.walkProfileName,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('profile-bio'),
                    controller: _bio,
                    maxLength: Profile.maxBio,
                    decoration: InputDecoration(labelText: l10n.walkProfileBio),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppListTile(
              key: const Key('profile-share-name'),
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(l10n.walkProfileShareName),
              subtitle: Text(l10n.walkProfileShareNameDescription),
              trailing: Switch(
                value: _shareName,
                onChanged: (on) => setState(() => _shareName = on),
              ),
              onTap: () => setState(() => _shareName = !_shareName),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoChoice { gallery, camera, remove }
