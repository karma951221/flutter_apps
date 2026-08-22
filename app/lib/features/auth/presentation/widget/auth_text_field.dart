import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';

class AuthTextField extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        enabled: enabled,
        autofillHints: autofillHints,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label, counterText: ''),
      ),
    );
  }
}
