import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../cubit/sign_up_cubit.dart';
import '../cubit/submit_state.dart';
import '../widget/auth_text_field.dart';
import '../widget/failure_text.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignUpCubit>(),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _nickname = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _nickname.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<SignUpCubit>().submit(
      email: _email.text,
      password: _password.text,
      nickname: _nickname.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: BlocBuilder<SignUpCubit, SubmitState>(
        builder: (context, state) {
          final busy = state is SubmitInProgress;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    AuthTextField(
                      controller: _email,
                      label: '이메일',
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    AuthTextField(
                      controller: _nickname,
                      label: '닉네임 (2~20자)',
                      enabled: !busy,
                      textInputAction: TextInputAction.next,
                      maxLength: Validators.nicknameMaxLength,
                      validator: Validators.nickname,
                    ),
                    AuthTextField(
                      controller: _password,
                      label: '비밀번호 (8자 이상)',
                      enabled: !busy,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                    ),
                    AuthTextField(
                      controller: _passwordConfirm,
                      label: '비밀번호 확인',
                      enabled: !busy,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          Validators.passwordConfirm(v, _password.text),
                    ),
                    if (state is SubmitFailure) FailureText(state.failure),
                    AppButton.primary(
                      label: '가입하기',
                      onPressed: _submit,
                      isLoading: busy,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
