import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/validation_localizations.dart';
import '../../../../core/validation/validators.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/widget/app_button.dart';
import '../cubit/sign_up_cubit.dart';
import '../cubit/submit_state.dart';
import '../widget/auth_header.dart';
import '../widget/auth_scaffold.dart';
import '../widget/auth_text_field.dart';
import '../widget/failure_text.dart';
import '../../../../l10n/app_localizations.dart';

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

  /// 이메일 칸을 벗어나는 순간을 잡아 닉네임 제안값을 넣는다.
  final _emailFocus = FocusNode();

  /// 키보드의 '다음' 으로 필드를 순서대로 넘긴다.
  final _nicknameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _passwordConfirmFocus = FocusNode();

  /// 사용자가 닉네임 칸에 손댔는가. 손댔으면 제안값으로 덮어쓰지 않는다 —
  /// 지운 것도 결정이다.
  bool _nicknameEdited = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChanged);
  }

  @override
  void dispose() {
    _email.dispose();
    _nickname.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _emailFocus
      ..removeListener(_onEmailFocusChanged)
      ..dispose();
    _nicknameFocus.dispose();
    _passwordFocus.dispose();
    _passwordConfirmFocus.dispose();
    super.dispose();
  }

  void _onEmailFocusChanged() {
    if (!_emailFocus.hasFocus) _suggestNickname();
  }

  /// 이메일 로컬 파트를 닉네임 제안값으로 넣는다.
  ///
  /// 기본값은 추천으로 읽히므로 규칙(2~20자)에 맞을 때만 채우고, 사용자가
  /// 닉네임 칸에 손댔거나 이미 값이 있으면 아무것도 하지 않는다
  /// (ux-psychology-review.md 3번).
  void _suggestNickname() {
    if (_nicknameEdited || _nickname.text.isNotEmpty) return;
    final local = _email.text.trim().split('@').first;
    final candidate = local.length > Validators.nicknameMaxLength
        ? local.substring(0, Validators.nicknameMaxLength)
        : local;
    if (Validators.nickname(candidate) != null) return;
    _nickname.text = candidate;
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
        final l10n = AppLocalizations.of(context);
        return AuthScaffold(
          showAppBar: true,
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(
                    title: l10n.authSignUp,
                    description: l10n.authSignUpDescription,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // key 는 E2E 셀렉터. 라벨 문구 변경에 테스트가 끌려가지 않게 한다.
                  AuthTextField(
                    key: const Key('signUp.email'),
                    controller: _email,
                    focusNode: _emailFocus,
                    label: l10n.authEmailLabel,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) =>
                        Validators.email(value)?.localized(context),
                    onSubmitted: _nicknameFocus.requestFocus,
                  ),
                  AuthTextField(
                    key: const Key('signUp.nickname'),
                    controller: _nickname,
                    focusNode: _nicknameFocus,
                    label: l10n.authNicknameLabel,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    maxLength: Validators.nicknameMaxLength,
                    validator: (value) =>
                        Validators.nickname(value)?.localized(context),
                    onChanged: (_) => _nicknameEdited = true,
                    onSubmitted: _passwordFocus.requestFocus,
                  ),
                  AuthTextField(
                    key: const Key('signUp.password'),
                    controller: _password,
                    focusNode: _passwordFocus,
                    label: l10n.authPasswordWithRuleLabel,
                    enabled: !busy,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) =>
                        Validators.password(value)?.localized(context),
                    onSubmitted: _passwordConfirmFocus.requestFocus,
                  ),
                  AuthTextField(
                    key: const Key('signUp.passwordConfirm'),
                    controller: _passwordConfirm,
                    focusNode: _passwordConfirmFocus,
                    label: l10n.authPasswordConfirmLabel,
                    enabled: !busy,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => Validators.passwordConfirm(
                      v,
                      _password.text,
                    )?.localized(context),
                    onSubmitted: _submit,
                  ),
                  if (state is SubmitFailure) FailureText(state.failure),
                  AppButton.primary(
                    label: l10n.authSignUpSubmit,
                    onPressed: _submit,
                    isLoading: busy,
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
