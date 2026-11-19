import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 키 · 비밀번호처럼 가려 두는 입력란 — 오른쪽 눈 아이콘으로 보기 · 가리기.
///
/// 자동 고침과 추천 단어는 끈다(키가 사전 단어로 바뀌거나 키보드 기록에 남지 않게).
class ObscuredKeyField extends StatefulWidget {
  const ObscuredKeyField({
    required this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.showTooltip,
    this.hideTooltip,
    this.toggleKey,
    super.key,
  });

  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 눈 아이콘 툴팁. 없으면 현재 언어의 '보기' · '숨기기'.
  final String? showTooltip;
  final String? hideTooltip;

  /// 눈 아이콘 버튼에 붙는 키.
  final Key? toggleKey;

  @override
  State<ObscuredKeyField> createState() => _ObscuredKeyFieldState();
}

class _ObscuredKeyFieldState extends State<ObscuredKeyField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscure,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        helperText: widget.helperText,
        suffixIcon: IconButton(
          key: widget.toggleKey,
          tooltip: _obscure
              ? widget.showTooltip ?? l10n.commonShowValue
              : widget.hideTooltip ?? l10n.commonHideValue,
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
