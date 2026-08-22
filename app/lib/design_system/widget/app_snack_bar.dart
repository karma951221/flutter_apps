import 'package:flutter/material.dart';

enum AppSnackBarType { info, success, error }

/// 공통 Snackbar 표시 도우미.
class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = switch (type) {
      AppSnackBarType.info => null,
      AppSnackBarType.success => colors.primaryContainer,
      AppSnackBarType.error => colors.errorContainer,
    };
    final contentColor = switch (type) {
      AppSnackBarType.info => null,
      AppSnackBarType.success => colors.onPrimaryContainer,
      AppSnackBarType.error => colors.onErrorContainer,
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          content: Text(message, style: TextStyle(color: contentColor)),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction),
        ),
      );
  }
}
