import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';

/// 인증 화면 공통 입력 필드.
///
/// 모양은 [InputDecorationTheme] 을 따르고, 여기서는 인증 폼에만 필요한 두 가지를
/// 더한다 — 필드 아래 간격을 고정해 검증 문구 위치를 화면마다 같게 만들고,
/// 비밀번호 필드에는 보기 토글을 붙인다.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.autofillHints,
    this.maxLength,
    this.focusNode,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final FocusNode? focusNode;

  /// 키보드의 완료/다음 키를 눌렀을 때. 다음 필드로 옮기거나 폼을 제출한다.
  final VoidCallback? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// 토글 상태는 화면이 아니라 필드가 들고 있어야 한다.
  /// 폼 상태에 두면 비밀번호 필드가 둘인 화면에서 서로 간섭한다.
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        validator: widget.validator,
        obscureText: _obscured,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        autofillHints: widget.autofillHints,
        maxLength: widget.maxLength,
        onFieldSubmitted: widget.onSubmitted == null
            ? null
            : (_) => widget.onSubmitted!(),
        decoration: InputDecoration(
          labelText: widget.label,
          counterText: '',
          suffixIcon: widget.obscureText ? _obscureToggle() : null,
        ),
      ),
    );
  }

  Widget _obscureToggle() {
    return IconButton(
      // 아이콘만 있는 버튼이라 tooltip 이 곧 스크린리더 라벨이 된다.
      tooltip: _obscured ? '비밀번호 표시' : '비밀번호 숨기기',
      icon: Icon(
        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: widget.enabled
          ? () => setState(() => _obscured = !_obscured)
          : null,
    );
  }
}
