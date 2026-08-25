import 'package:flutter/material.dart';

import 'app_button.dart';

/// 되돌릴 수 없는 동작을 확인받는 공용 다이얼로그.
///
/// 삭제 · 탈퇴 · 차단처럼 결과를 되돌리기 어려운 동작에서 같은 모양
/// (`AlertDialog` + 취소 + destructive 색 확인 버튼)을 화면마다 다시 쓰지
/// 않기 위해 승격했다 — `feed_page` · `profile_page`의 차단 확인과
/// `account_settings_page`의 탈퇴 확인이 이 모양을 그대로 반복하고 있었다
/// (CLAUDE.md 규칙 4의 "반복 사용되거나 새 화면에도 공통으로 쓸 모양"
/// 기준).
abstract final class AppConfirmDialog {
  /// 다이얼로그를 띄우고 확인 여부를 돌려준다. 취소하거나 바깥을 눌러 닫으면
  /// `false`다.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    String cancelLabel = '취소',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          AppButton.text(
            label: cancelLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: confirmLabel,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
