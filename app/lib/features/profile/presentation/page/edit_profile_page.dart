import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../domain/entity/profile_update.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

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
  final _avatarUrlController = TextEditingController();
  String? _initializedProfileId;
  bool _wasSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  void _populate(ProfileState state) {
    final profile = state.profile;
    if (profile == null || _initializedProfileId == profile.id) return;
    _initializedProfileId = profile.id;
    _nicknameController.text = profile.nickname;
    _bioController.text = profile.bio ?? '';
    _avatarUrlController.text = profile.avatarUrl ?? '';
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ProfileCubit>().save(
      ProfileUpdate(
        nickname: _nicknameController.text,
        bio: _bioController.text,
        avatarUrl: _avatarUrlController.text,
      ),
    );
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
        return SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Center(
                  child: AppAvatar(
                    nickname: _nicknameController.text,
                    imageUrl: _avatarUrlController.text,
                    radius: 48,
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
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _avatarUrlController,
                  decoration: const InputDecoration(labelText: '프로필 사진 URL'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: '저장',
                  onPressed: _save,
                  isLoading: state.isSaving,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
