import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import '../../../../core/l10n/failure_localizations.dart';
import '../../../../core/l10n/validation_localizations.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../../../../design_system/widget/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.passwordChangeTitle)),
      body: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listener: (context, state) {
          switch (state) {
            case ChangePasswordSuccess():
              AppSnackBar.show(
                context,
                message: l10n.passwordChangeSucceeded,
                type: AppSnackBarType.success,
              );
              Navigator.of(context).pop();
            case ChangePasswordFailure(:final failure):
              AppSnackBar.show(
                context,
                message: failure.localizedMessage(context),
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
                    label: l10n.passwordChangeNewLabel,
                    obscureText: true,
                    enabled: !isBusy,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) =>
                        Validators.password(value)?.localized(context),
                  ),
                  AuthTextField(
                    controller: _confirmController,
                    label: l10n.passwordChangeConfirmLabel,
                    obscureText: true,
                    enabled: !isBusy,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) => Validators.passwordConfirm(
                      value,
                      _passwordController.text,
                    )?.localized(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.primary(
                    label: l10n.passwordChangeAction,
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
}
