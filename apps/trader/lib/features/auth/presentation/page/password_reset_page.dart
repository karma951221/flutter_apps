import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/validation_localizations.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../cubit/password_reset_state.dart';
import '../widget/auth_header.dart';
import '../widget/auth_scaffold.dart';
import '../widget/auth_text_field.dart';
import '../widget/failure_text.dart';
import '../../../../l10n/app_localizations.dart';

/// 비밀번호 재설정.
///
/// 이메일 → 코드 → 새 비밀번호 세 단계가 한 화면 안에서 진행된다.
/// 링크(딥링크) 방식이 아니라 6자리 코드 방식이라 라우팅이 필요 없다.
/// 단계가 바뀌어도 헤더 자리와 여백은 그대로 두어 화면이 튀지 않게 한다.
class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PasswordResetCubit>(),
      child: const _PasswordResetView(),
    );
  }
}

class _PasswordResetView extends StatelessWidget {
  const _PasswordResetView();

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showAppBar: true,
      child: BlocBuilder<PasswordResetCubit, PasswordResetState>(
        builder: (context, state) => switch (state.step) {
          PasswordResetStep.requestCode => _RequestCodeStep(state: state),
          PasswordResetStep.verifyCode => _VerifyCodeStep(state: state),
          PasswordResetStep.newPassword => _NewPasswordStep(state: state),
          PasswordResetStep.done => const _DoneStep(),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- 1단계
class _RequestCodeStep extends StatefulWidget {
  const _RequestCodeStep({required this.state});
  final PasswordResetState state;

  @override
  State<_RequestCodeStep> createState() => _RequestCodeStepState();
}

class _RequestCodeStepState extends State<_RequestCodeStep> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.state.email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetCubit>().sendCode(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.state.isLoading;
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: l10n.authPasswordResetTitle,
            description: l10n.authPasswordResetDescription,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthTextField(
            key: const Key('passwordReset.email'),
            controller: _email,
            label: l10n.authEmailLabel,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) => Validators.email(value)?.localized(context),
            onSubmitted: _submit,
          ),
          FailureText(widget.state.failure),
          AppButton.primary(
            label: l10n.authPasswordResetSendCode,
            onPressed: _submit,
            isLoading: busy,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 2단계
class _VerifyCodeStep extends StatefulWidget {
  const _VerifyCodeStep({required this.state});
  final PasswordResetState state;

  @override
  State<_VerifyCodeStep> createState() => _VerifyCodeStepState();
}

class _VerifyCodeStepState extends State<_VerifyCodeStep> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetCubit>().verifyCode(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.state.isLoading;
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: l10n.authPasswordResetCodeTitle,
            description: l10n.authPasswordResetCodeDescription(
              widget.state.email,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthTextField(
            key: const Key('passwordReset.code'),
            controller: _code,
            label: l10n.authPasswordResetCodeLabel,
            enabled: !busy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            validator: (value) => Validators.otpCode(value)?.localized(context),
            onSubmitted: _submit,
          ),
          FailureText(widget.state.failure),
          AppButton.primary(
            label: l10n.authPasswordResetVerify,
            onPressed: _submit,
            isLoading: busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.text(
            label: l10n.authPasswordResetChangeEmail,
            onPressed: busy
                ? null
                : () => context.read<PasswordResetCubit>().backToEmail(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 3단계
class _NewPasswordStep extends StatefulWidget {
  const _NewPasswordStep({required this.state});
  final PasswordResetState state;

  @override
  State<_NewPasswordStep> createState() => _NewPasswordStepState();
}

class _NewPasswordStepState extends State<_NewPasswordStep> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _passwordConfirmFocus = FocusNode();

  @override
  void dispose() {
    _password.dispose();
    _passwordConfirm.dispose();
    _passwordConfirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetCubit>().updatePassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.state.isLoading;
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: l10n.authNewPasswordTitle,
            description: l10n.authNewPasswordDescription,
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthTextField(
            key: const Key('passwordReset.password'),
            controller: _password,
            label: l10n.authNewPasswordLabel,
            enabled: !busy,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.password(value)?.localized(context),
            onSubmitted: _passwordConfirmFocus.requestFocus,
          ),
          AuthTextField(
            key: const Key('passwordReset.passwordConfirm'),
            controller: _passwordConfirm,
            focusNode: _passwordConfirmFocus,
            label: l10n.authNewPasswordConfirmLabel,
            enabled: !busy,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.passwordConfirm(
              v,
              _password.text,
            )?.localized(context),
            onSubmitted: _submit,
          ),
          FailureText(widget.state.failure),
          AppButton.primary(
            label: l10n.authPasswordChangeSubmit,
            onPressed: _submit,
            isLoading: busy,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 완료
class _DoneStep extends StatelessWidget {
  const _DoneStep();

  /// 완료 표시는 문구보다 먼저 눈에 들어와야 해서 본문 아이콘 크기를 따로 둔다.
  static const _iconSize = 64.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle,
          size: _iconSize,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.authPasswordChangedTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.authPasswordChangedDescription,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(
          label: l10n.authGoToSignIn,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
