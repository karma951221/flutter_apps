import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 버튼의 공통 진입점.
///
/// 기본 모양은 [AppTheme]을 따르고, 화면별 조정은 [style]로 덧씌운다.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.style,
    super.key,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.style,
    super.key,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.style,
    super.key,
  }) : isLoading = false,
       _variant = _AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;
  final _AppButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      ),
      _AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      ),
      _AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      ),
    };
  }
}

enum _AppButtonVariant { primary, secondary, text }
