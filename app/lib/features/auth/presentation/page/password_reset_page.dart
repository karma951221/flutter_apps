import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../cubit/password_reset_state.dart';
import '../widget/auth_text_field.dart';
import '../widget/failure_text.dart';

/// 비밀번호 재설정.
///
/// 이메일 → 코드 → 새 비밀번호 세 단계가 한 화면 안에서 진행된다.
/// 링크(딥링크) 방식이 아니라 6자리 코드 방식이라 라우팅이 필요 없다.
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
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocBuilder<PasswordResetCubit, PasswordResetState>(
            builder: (context, state) => switch (state.step) {
              PasswordResetStep.requestCode => _RequestCodeStep(state: state),
              PasswordResetStep.verifyCode => _VerifyCodeStep(state: state),
              PasswordResetStep.newPassword => _NewPasswordStep(state: state),
              PasswordResetStep.done => const _DoneStep(),
            },
          ),
        ),
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
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Text('가입한 이메일로 6자리 코드를 보내드립니다.'),
          const SizedBox(height: AppSpacing.lg),
          AuthTextField(
            controller: _email,
            label: '이메일',
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
          ),
          FailureText(widget.state.failure),
          AppButton.primary(
            label: '코드 받기',
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
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('${widget.state.email} 으로 보낸 6자리 코드를 입력하세요.'),
          const SizedBox(height: AppSpacing.lg),
          AuthTextField(
            controller: _code,
            label: '인증 코드',
            enabled: !busy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            validator: Validators.otpCode,
          ),
          FailureText(widget.state.failure),
          AppButton.primary(label: '확인', onPressed: _submit, isLoading: busy),
          const SizedBox(height: AppSpacing.sm),
          AppButton.text(
            label: '이메일 다시 입력',
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

  @override
  void dispose() {
    _password.dispose();
    _passwordConfirm.dispose();
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
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          const Text('새 비밀번호를 입력하세요.'),
          const SizedBox(height: AppSpacing.lg),
          AuthTextField(
            controller: _password,
            label: '새 비밀번호 (8자 이상)',
            enabled: !busy,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
          ),
          AuthTextField(
            controller: _passwordConfirm,
            label: '새 비밀번호 확인',
            enabled: !busy,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.passwordConfirm(v, _password.text),
          ),
          FailureText(widget.state.failure),
          AppButton.primary(
            label: '비밀번호 변경',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.check_circle,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('비밀번호가 변경되었습니다.', textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        const Text('새 비밀번호로 다시 로그인하세요.', textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(label: '로그인하러 가기', onPressed: () => context.pop()),
      ],
    );
  }
}
