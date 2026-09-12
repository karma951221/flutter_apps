import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';
import 'app_button.dart';

/// 되돌리기 어려운 동작을 확인받는 공용 다이얼로그.
///
/// 삭제 · 탈퇴 · 차단처럼 결과를 되돌리기 어려운 동작에서 같은 모양
/// (`AlertDialog` + 취소 + destructive 색 확인 버튼)을 화면마다 다시 쓰지
/// 않기 위해 승격했다 (CLAUDE.md 규칙 4의 "반복 사용되거나 새 화면에도 공통으로
/// 쓸 모양" 기준).
///
/// 승격 뒤에도 게시물 삭제 · 댓글 삭제 · 로그아웃 · 작성 취소 네 곳이 같은
/// 모양을 손으로 다시 쌓고 있었다. 그 결과 **가장 되돌리기 어려운 동작인 삭제만
/// destructive 색을 못 받고** 있었다 — 확인 버튼 색을 [isDestructive] 로 고를 수
/// 있게 해서 네 곳을 모두 이 다이얼로그로 모았다 (2026-08-27 리뷰).
abstract final class AppConfirmDialog {
  /// 다이얼로그를 띄우고 확인 여부를 돌려준다. 취소하거나 바깥을 눌러 닫으면
  /// `false`다.
  ///
  /// [cancelLabel] 을 넘기지 않으면 현재 언어의 '취소'를 쓴다. 예전에는 한국어
  /// 문자열이 기본값으로 박혀 있어서, 호출부가 아무것도 넘기지 않는 탓에 화면
  /// 언어를 바꿔도 취소 버튼만 한국어로 남았다 (2026-08-27 리뷰).
  ///
  /// [isDestructive] 가 `false` 면 확인 버튼을 기본 색으로 그린다. 로그아웃처럼
  /// 다시 로그인하면 그만인 동작까지 빨갛게 칠하면, 정말 되돌릴 수 없는 삭제와
  /// 구분이 사라진다.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) async {
    final resolvedCancelLabel =
        cancelLabel ?? AppLocalizations.of(context).commonCancel;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          AppButton.text(
            label: resolvedCancelLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          AppButton.text(
            label: confirmLabel,
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
