import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_status_colors.dart';

/// 스낵바 유형 — [AppStatus] 와 같다(info · success · warning · error).
typedef AppSnackBarType = AppStatus;

/// 공통 Snackbar 표시 도우미.
///
/// 유형마다 아이콘과 색([AppStatusColors])이 다르다. 오른쪽 끝의 X 로 닫거나
/// 좌우로 밀어서 닫는다. 유형을 안 주면 info 다.
///
/// - 실패 · 오류 안내 → [error]
/// - 완료 · 저장 → [success]
/// - 되돌릴 수 없거나 조심해야 할 것 → [warning]
/// - 그 밖 → [info]
class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final colors = AppStatusColors.of(context).forStatus(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // 안내가 유효한 시간이 정해져 있으면(예: '한 번 더 누르면 종료') 그만큼만 보인다.
          duration: duration ?? const Duration(milliseconds: 4000),
          backgroundColor: colors.background,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
          closeIconColor: colors.foreground,
          content: Row(
            children: [
              Icon(_icon(type), color: colors.foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.foreground),
                ),
              ),
            ],
          ),
          action: actionLabel == null || onAction == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: colors.foreground,
                  onPressed: onAction,
                ),
        ),
      );
  }

  static void info(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) => show(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );

  static void success(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    context,
    message: message,
    type: AppSnackBarType.success,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void warning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    context,
    message: message,
    type: AppSnackBarType.warning,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void error(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) => show(
    context,
    message: message,
    type: AppSnackBarType.error,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static IconData _icon(AppSnackBarType type) => switch (type) {
    AppSnackBarType.info => Icons.info_outline,
    AppSnackBarType.success => Icons.check_circle_outline,
    AppSnackBarType.warning => Icons.warning_amber_rounded,
    AppSnackBarType.error => Icons.error_outline,
  };
}
