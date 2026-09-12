import 'package:flutter/material.dart';

import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';

/// 인증 화면 공통 입력 필드.
///
/// 모양은 [InputDecorationTheme] 을 따르고, 여기서는 인증 폼에만 필요한 것을
/// 더한다 — 필드 아래 간격을 고정해 검증 문구 위치를 화면마다 같게 만들고,
/// 비밀번호 필드에는 보기 토글을 붙인다. [helperText] · [suffixIcon] 은 닉네임
/// 사전 확인처럼 검증과 별개인 안내를 같은 자리에 붙이기 위한 것이다.
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
    this.onChanged,
    this.helperText,
    this.helperColor,
    this.suffixIcon,
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

  /// 사용자가 직접 입력할 때만 불린다. 컨트롤러 값을 코드로 바꿀 때는 불리지
  /// 않으므로 "사용자가 손댔는가" 를 구분하는 데 쓴다.
  final ValueChanged<String>? onChanged;

  /// 검증 오류가 아닌 안내를 필드 아래에 붙인다. 오류가 있으면 오류가 이긴다.
  final String? helperText;

  /// [helperText] 의 색. 색은 화면이 테마에서 골라 넘긴다.
  final Color? helperColor;

  /// 필드 오른쪽에 붙일 위젯. 비밀번호 필드는 보기 토글이 그 자리를 쓰므로
  /// 무시된다.
  final Widget? suffixIcon;

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
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted == null
            ? null
            : (_) => widget.onSubmitted!(),
        decoration: InputDecoration(
          labelText: widget.label,
          counterText: '',
          helperText: widget.helperText,
          helperStyle: widget.helperColor == null
              ? null
              : TextStyle(color: widget.helperColor),
          suffixIcon: widget.obscureText ? _obscureToggle() : widget.suffixIcon,
        ),
      ),
    );
  }

  Widget _obscureToggle() {
    return IconButton(
      // 아이콘만 있는 버튼이라 tooltip 이 곧 스크린리더 라벨이 된다.
      tooltip: _obscured
          ? AppLocalizations.of(context).authPasswordShow
          : AppLocalizations.of(context).authPasswordHide,
      icon: Icon(
        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: widget.enabled
          ? () => setState(() => _obscured = !_obscured)
          : null,
    );
  }
}
