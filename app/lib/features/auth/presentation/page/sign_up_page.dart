import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../cubit/sign_up_cubit.dart';
import '../cubit/submit_state.dart';
import '../widget/auth_header.dart';
import '../widget/auth_scaffold.dart';
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

  /// 키보드의 '다음' 으로 필드를 순서대로 넘긴다.
  final _nicknameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _passwordConfirmFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _nickname.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _nicknameFocus.dispose();
    _passwordFocus.dispose();
    _passwordConfirmFocus.dispose();
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
    return BlocBuilder<SignUpCubit, SubmitState>(
      builder: (context, state) {
        final busy = state is SubmitInProgress;
        return AuthScaffold(
          showAppBar: true,
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: '회원가입',
                  description: '이메일과 닉네임만 있으면 바로 시작할 수 있습니다.',
                ),
                const SizedBox(height: AppSpacing.xl),
                // key 는 E2E 셀렉터. 라벨 문구 변경에 테스트가 끌려가지 않게 한다.
                AuthTextField(
                  key: const Key('signUp.email'),
                  controller: _email,
                  label: '이메일',
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  onSubmitted: _nicknameFocus.requestFocus,
                ),
                AuthTextField(
                  key: const Key('signUp.nickname'),
                  controller: _nickname,
                  focusNode: _nicknameFocus,
                  label: '닉네임 (2~20자)',
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  maxLength: Validators.nicknameMaxLength,
                  validator: Validators.nickname,
                  onSubmitted: _passwordFocus.requestFocus,
                ),
                AuthTextField(
                  key: const Key('signUp.password'),
                  controller: _password,
                  focusNode: _passwordFocus,
                  label: '비밀번호 (8자 이상)',
                  enabled: !busy,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onSubmitted: _passwordConfirmFocus.requestFocus,
                ),
                AuthTextField(
                  key: const Key('signUp.passwordConfirm'),
                  controller: _passwordConfirm,
                  focusNode: _passwordConfirmFocus,
                  label: '비밀번호 확인',
                  enabled: !busy,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.passwordConfirm(v, _password.text),
                  onSubmitted: _submit,
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
        );
      },
    );
  }
}
