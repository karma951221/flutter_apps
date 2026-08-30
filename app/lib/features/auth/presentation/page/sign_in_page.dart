import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../cubit/sign_in_cubit.dart';
import '../cubit/submit_state.dart';
import '../widget/auth_header.dart';
import '../widget/auth_scaffold.dart';
import '../widget/auth_text_field.dart';
import '../widget/failure_text.dart';
import '../../../../l10n/app_localizations.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignInCubit>(),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// 이메일에서 키보드의 '다음' 을 누르면 비밀번호로 넘긴다.
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<SignInCubit>().submit(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 성공 시 화면 전환은 여기서 하지 않는다.
    // AuthBloc 이 상태를 바꾸고 라우터가 알아서 홈으로 보낸다.
    return BlocBuilder<SignInCubit, SubmitState>(
      builder: (context, state) {
        final busy = state is SubmitInProgress;
        final l10n = AppLocalizations.of(context);
        return AuthScaffold(
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              // 한 번 제출한 뒤에는 입력하는 대로 검증한다.
              // 없으면 값을 고쳐도 이전 오류 문구가 그대로 남는다.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    showWordmark: true,
                    description: l10n.authSignInDescription,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthTextField(
                    // E2E 셀렉터. 라벨 문구가 바뀌어도 테스트가 깨지지 않게 한다.
                    key: const Key('signIn.email'),
                    controller: _email,
                    label: l10n.authEmailLabel,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onSubmitted: _passwordFocus.requestFocus,
                  ),
                  AuthTextField(
                    key: const Key('signIn.password'),
                    controller: _password,
                    focusNode: _passwordFocus,
                    label: l10n.authPasswordLabel,
                    enabled: !busy,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onSubmitted: _submit,
                  ),
                  if (state is SubmitFailure) FailureText(state.failure),
                  AppButton.primary(
                    label: l10n.authSignIn,
                    onPressed: _submit,
                    isLoading: busy,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.text(
                    label: l10n.authForgotPassword,
                    onPressed: busy
                        ? null
                        : () => context.push(Routes.passwordReset),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Text(
                    l10n.authNoAccountPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    label: l10n.authSignUp,
                    onPressed: busy ? null : () => context.push(Routes.signUp),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
