import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/media/image_picker_service.dart';
import '../../../../core/media/image_uploader.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entity/profile_update.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

/// 아바타 이미지를 담는 Storage 버킷.
const _avatarBucket = 'avatars';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ProfileCubit>()..load(),
    child: const _EditProfileView(),
  );
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl;

  /// 고르기만 하고 아직 올리지 않은 이미지.
  ///
  /// 저장할 때 비로소 업로드한다. 고르는 즉시 올리면 저장하지 않고 화면을
  /// 떠났을 때 객체가 그대로 남는다.
  PreparedImage? _pendingAvatar;

  bool _isUploadingAvatar = false;
  String? _initializedProfileId;
  bool _wasSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _populate(ProfileState state) {
    final profile = state.profile;
    if (profile == null || _initializedProfileId == profile.id) return;
    _initializedProfileId = profile.id;
    _nicknameController.text = profile.nickname;
    _bioController.text = profile.bio ?? '';
    _avatarUrl = profile.avatarUrl;
  }

  /// 저장 흐름. 업로드 → 프로필 갱신 → 정리 순서로 진행한다.
  ///
  /// 업로드가 프로필 갱신보다 앞서야 새 URL 을 같은 요청에 담을 수 있다.
  /// 갱신이 실패하면 방금 올린 객체를, 성공하면 이전 객체를 치운다. 정리는
  /// best-effort 라서 실패해도 저장 결과를 뒤집지 않는다.
  Future<void> _save() async {
    if (_isUploadingAvatar) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<ProfileCubit>();
    final authBloc = context.read<AuthBloc>();
    final uploader = getIt<ImageUploader>();
    final pending = _pendingAvatar;
    final previousAvatarUrl = _avatarUrl;

    var avatarUrl = previousAvatarUrl;
    if (pending != null) {
      setState(() => _isUploadingAvatar = true);
      try {
        avatarUrl = await uploader.upload(
          bucket: _avatarBucket,
          bytes: pending.bytes,
          contentType: pending.contentType,
          extension: pending.extension,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _isUploadingAvatar = false);
        AppSnackBar.show(
          context,
          message: '프로필 사진을 업로드하지 못했습니다.',
          type: AppSnackBarType.error,
        );
        return;
      }
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
    }

    await cubit.save(
      ProfileUpdate(
        nickname: _nicknameController.text,
        bio: _bioController.text,
        avatarUrl: avatarUrl,
      ),
    );

    final didFail = cubit.state.failure != null;
    if (pending != null) {
      await uploader.removeByPublicUrl(
        bucket: _avatarBucket,
        publicUrl: didFail ? avatarUrl : previousAvatarUrl,
      );
    }
    if (didFail) return;

    // 로그인 때 만들어진 사용자 스냅샷을 새로 읽게 한다. 이게 없으면 방금
    // 바꾼 닉네임·사진이 다음에 쓰는 글에 옛 값으로 붙는다.
    authBloc.add(const AuthEvent.userRefreshRequested());

    if (!mounted) return;
    setState(() {
      _pendingAvatar = null;
      _avatarUrl = avatarUrl;
    });
  }

  Future<void> _pickAvatar() async {
    if (_isUploadingAvatar) return;
    final picker = getIt<ImagePickerService>();
    final image = await picker.pickImage();
    if (image == null || !mounted) return;

    try {
      final prepared = await picker.prepare(image);
      if (!mounted) return;
      setState(() => _pendingAvatar = prepared);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: '프로필 사진을 불러오지 못했습니다.',
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('프로필 편집')),
    body: BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.profile != current.profile ||
          previous.isSaving != current.isSaving,
      listener: (context, state) {
        _populate(state);
        final didFinishSaving = _wasSaving && !state.isSaving;
        _wasSaving = state.isSaving;
        if (didFinishSaving && state.failure != null) {
          AppSnackBar.show(
            context,
            message: state.failure?.message ?? '프로필을 저장하지 못했습니다',
            type: AppSnackBarType.error,
          );
        }
        if (didFinishSaving && state.failure == null && state.profile != null) {
          AppSnackBar.show(
            context,
            message: '프로필을 저장했습니다',
            type: AppSnackBarType.success,
          );
        }
      },
      builder: (context, state) {
        _populate(state);
        if (state.isLoading && state.profile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.profile == null) {
          return const SizedBox.shrink();
        }
        final isBusy = state.isSaving || _isUploadingAvatar;
        return SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Center(
                  child: AppAvatar(
                    nickname: _nicknameController.text,
                    imageUrl: _avatarUrl,
                    imageBytes: _pendingAvatar?.bytes,
                    radius: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: AppButton.secondary(
                    label: '사진 선택',
                    onPressed: isBusy ? null : _pickAvatar,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '닉네임'),
                  textInputAction: TextInputAction.next,
                  validator: Validators.nickname,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: '자기소개'),
                  maxLength: Validators.bioMaxLength,
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: '저장',
                  onPressed: isBusy ? null : _save,
                  isLoading: isBusy,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
