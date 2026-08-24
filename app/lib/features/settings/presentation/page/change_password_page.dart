import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../auth/presentation/widget/auth_text_field.dart';
import '../cubit/change_password_cubit.dart';
import '../cubit/change_password_state.dart';

/// 비밀번호 변경 화면.
///
/// 지금 비밀번호를 다시 묻지 않는다. 이미 로그인한 세션으로만 들어오는 화면이고,
/// Supabase 의 비밀번호 교체가 세션을 근거로 동작하기 때문이다. 세션 없이 바꾸는
/// 경로는 auth 의 재설정(코드 검증)이 따로 맡는다.
class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ChangePasswordCubit>(),
    child: const _ChangePasswordView(),
  );
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// 검증을 통과한 경우에만 제출한다.
  ///
  /// 길이·일치 검사는 여기서 끝낸다. 서버에 갔다 와서 실패하는 것보다 빠르고,
  /// 두 칸이 어긋난 채로 요청을 보내면 사용자가 무엇을 바꿨는지 알 수 없다.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<ChangePasswordCubit>().submit(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('비밀번호 변경')),
    body: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listener: (context, state) {
        switch (state) {
          case ChangePasswordSuccess():
            AppSnackBar.show(
              context,
              message: '비밀번호를 변경했습니다',
              type: AppSnackBarType.success,
            );
            Navigator.of(context).pop();
          case ChangePasswordFailure(:final failure):
            AppSnackBar.show(
              context,
              message: failure.message ?? '비밀번호를 변경하지 못했습니다',
              type: AppSnackBarType.error,
            );
          case ChangePasswordIdle():
          case ChangePasswordInProgress():
            break;
        }
      },
      builder: (context, state) {
        final isBusy = state is ChangePasswordInProgress;
        return SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AuthTextField(
                  controller: _passwordController,
                  label: '새 비밀번호',
                  obscureText: true,
                  enabled: !isBusy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                ),
                AuthTextField(
                  controller: _confirmController,
                  label: '새 비밀번호 확인',
                  obscureText: true,
                  enabled: !isBusy,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => Validators.passwordConfirm(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton.primary(
                  label: '변경',
                  onPressed: isBusy ? null : _submit,
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
