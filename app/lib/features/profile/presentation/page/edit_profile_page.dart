import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../core/l10n/validation_localizations.dart';
import '../../../../core/media/image_picker_service.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_avatar.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entity/avatar_image_draft.dart';
import '../../domain/entity/profile_update.dart';
import '../cubit/nickname_check.dart';
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
  String? _avatarUrl;

  /// 고르기만 하고 아직 올리지 않은 이미지.
  ///
  /// 저장할 때 비로소 업로드한다. 고르는 즉시 올리면 저장하지 않고 화면을
  /// 떠났을 때 객체가 그대로 남는다.
  PreparedImage? _pendingAvatar;

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

  /// 저장을 요청한다.
  ///
  /// 업로드 · 프로필 갱신 · 옛 이미지 정리의 순서와 보상 처리는 usecase 의
  /// `UpdateAvatarScenario` 가 소유한다. 화면은 무엇을 저장할지만 넘긴다.
  Future<void> _save() async {
    final cubit = context.read<ProfileCubit>();
    if (cubit.state.isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authBloc = context.read<AuthBloc>();
    final pending = _pendingAvatar;

    await cubit.save(
      ProfileUpdate(
        nickname: _nicknameController.text,
        bio: _bioController.text,
        // 지금 쓰고 있는 URL 을 그대로 보낸다. 새 이미지가 있으면 usecase 가
        // 업로드한 URL 로 바꾸고, 이 값이 정리 대상이 된다.
        avatarUrl: _avatarUrl,
      ),
      newAvatar: pending == null
          ? null
          : AvatarImageDraft(
              bytes: pending.bytes,
              contentType: pending.contentType,
              extension: pending.extension,
            ),
    );

    if (cubit.state.failure != null) return;

    // 로그인 때 만들어진 사용자 스냅샷을 새로 읽게 한다. 이게 없으면 방금
    // 바꾼 닉네임·사진이 다음에 쓰는 글에 옛 값으로 붙는다.
    authBloc.add(const AuthEvent.userRefreshRequested());

    if (!mounted) return;
    setState(() {
      _pendingAvatar = null;
      _avatarUrl = cubit.state.profile?.avatarUrl ?? _avatarUrl;
    });
  }

  /// 닉네임 입력창에 사전 확인 결과를 붙인다.
  ///
  /// 최종 판정은 DB 제약이다. 여기서 하는 말은 저장을 누르기 전에 알려주는
  /// 안내이므로, 확인에 실패했을 때(= idle)는 아무것도 덧붙이지 않는다.
  InputDecoration _nicknameDecoration(
    BuildContext context,
    NicknameCheck check,
  ) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final (message, color, icon) = switch (check) {
      NicknameCheckIdle() => (null, null, null),
      NicknameCheckChecking() => (l10n.profileNicknameChecking, null, null),
      NicknameCheckAvailable() => (
        l10n.profileNicknameAvailable,
        colors.primary,
        Icon(Icons.check_circle_outline, color: colors.primary),
      ),
      NicknameCheckTaken() => (
        l10n.profileNicknameTaken,
        colors.error,
        Icon(Icons.error_outline, color: colors.error),
      ),
    };

    return InputDecoration(
      labelText: l10n.profileNicknameLabel,
      helperText: message,
      helperStyle: color == null ? null : TextStyle(color: color),
      suffixIcon: switch (check) {
        NicknameCheckChecking() => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: AppSpacing.md,
            height: AppSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        _ => icon,
      },
    );
  }

  Future<void> _pickAvatar() async {
    if (context.read<ProfileCubit>().state.isSaving) return;
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
        message: AppLocalizations.of(context).profileAvatarPickFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
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
              message:
                  state.failure?.localizedMessage(context) ??
                  l10n.profileSaveFailed,
              type: AppSnackBarType.error,
            );
          }
          if (didFinishSaving &&
              state.failure == null &&
              state.profile != null) {
            AppSnackBar.show(
              context,
              message: l10n.profileSaveSucceeded,
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
          final isBusy = state.isSaving;
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
                      label: l10n.profileChoosePhoto,
                      onPressed: isBusy ? null : _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: _nicknameDecoration(
                      context,
                      state.nicknameCheck,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        Validators.nickname(value)?.localized(context),
                    onChanged: context.read<ProfileCubit>().checkNickname,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      labelText: l10n.profileBioLabel,
                    ),
                    maxLength: Validators.bioMaxLength,
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.primary(
                    label: l10n.commonSave,
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
}
