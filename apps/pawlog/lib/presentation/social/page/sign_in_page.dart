import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../common/widget/pawlog_primary_button.dart';
import '../../theme/pawlog_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_form_state.dart';

/// 로그인 · 가입 한 화면(plan 결정 7). 글자 버튼으로 두 모드를 오간다.
///
/// 성공하면 [onSignedIn] 을 한 번 부른다 — 어디로 갈지는 라우터가 정한다.
class SignInPage extends StatelessWidget {
  const SignInPage({required this.onSignedIn, super.key});

  final VoidCallback onSignedIn;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<AuthCubit>(),
    child: _SignInView(onSignedIn: onSignedIn),
  );
}

class _SignInView extends StatefulWidget {
  const _SignInView({required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  void _toggleMode() {
    context.read<AuthCubit>().clearFailure();
    _formKey.currentState?.reset();
    setState(() => _isSignUp = !_isSignUp);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<AuthCubit>();
    if (_isSignUp) {
      cubit.signUp(
        email: _email.text,
        password: _password.text,
        nickname: _nickname.text,
      );
    } else {
      cubit.signIn(email: _email.text, password: _password.text);
    }
  }

  static bool _isNicknameTaken(Failure failure) =>
      failure.failureCode == FailureCode.nicknameTaken;

  void _onState(BuildContext context, AuthFormState state) {
    switch (state) {
      case AuthFormSucceeded():
        widget.onSignedIn();
      // 닉네임 중복은 닉네임 칸 아래에 보인다.
      case AuthFormFailed(:final failure) when !_isNicknameTaken(failure):
        AppSnackBar.show(
          context,
          message: failure.failureCode == FailureCode.invalidCredentials
              ? AppLocalizations.of(context).walkSocialAuthFailed
              : failure.localizedMessage(context),
          type: AppSnackBarType.error,
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<AuthCubit, AuthFormState>(
      listener: _onState,
      builder: (context, state) {
        final busy = state is AuthFormSubmitting || state is AuthFormSucceeded;
        final nicknameError = switch (state) {
          AuthFormFailed(:final failure) when _isNicknameTaken(failure) =>
            l10n.walkSocialNicknameTaken,
          _ => null,
        };
        final title = _isSignUp ? l10n.walkSocialSignUp : l10n.walkSocialSignIn;

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(PawlogSize.gutter),
                      children: [
                        Text(
                          l10n.walkSocialSignInRequired,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: PawlogSpacing.lg),
                        TextFormField(
                          key: const Key('sign-in-email'),
                          controller: _email,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.walkSocialEmail,
                          ),
                          validator: (value) =>
                              Validators.email(value)?.localized(context),
                        ),
                        const SizedBox(height: PawlogSpacing.md),
                        TextFormField(
                          key: const Key('sign-in-password'),
                          controller: _password,
                          enabled: !busy,
                          obscureText: true,
                          autofillHints: [
                            _isSignUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          textInputAction: _isSignUp
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: _isSignUp ? null : (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l10n.walkSocialPassword,
                          ),
                          validator: (value) =>
                              Validators.password(value)?.localized(context),
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: PawlogSpacing.md),
                          TextFormField(
                            key: const Key('sign-in-nickname'),
                            controller: _nickname,
                            enabled: !busy,
                            autofillHints: const [AutofillHints.nickname],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            onChanged: (_) =>
                                context.read<AuthCubit>().clearFailure(),
                            decoration: InputDecoration(
                              labelText: l10n.walkSocialNickname,
                              errorText: nicknameError,
                            ),
                            validator: (value) =>
                                Validators.nickname(value)?.localized(context),
                          ),
                        ],
                        const SizedBox(height: PawlogSpacing.sm),
                        Center(
                          child: AppButton.text(
                            key: const Key('sign-in-switch'),
                            label: _isSignUp
                                ? l10n.walkSocialSwitchToSignIn
                                : l10n.walkSocialSwitchToSignUp,
                            onPressed: busy ? null : _toggleMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PawlogBottomAction(
                  child: PawlogPrimaryButton(
                    key: const Key('sign-in-submit'),
                    label: title,
                    isLoading: busy,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
