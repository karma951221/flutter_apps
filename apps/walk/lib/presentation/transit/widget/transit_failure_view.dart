import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/transit_failure.dart';
import 'transit_failure_cause.dart';

/// 길찾기 실패 안내. 키 없음 · 키 거부는 [onOpenKeySettings], 네트워크 · 서버 오류는 [onRetry] 버튼.
/// 원인 원문이 있으면 아래에 [TransitFailureCause] 로 함께 보인다.
class TransitFailureView extends StatelessWidget {
  const TransitFailureView({
    required this.failure,
    required this.onOpenKeySettings,
    this.onRetry,
    super.key,
  });

  final TransitFailure failure;
  final VoidCallback onOpenKeySettings;

  /// null 이면 다시 시도 버튼을 두지 않는다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyAction = (l10n.walkTransitOpenKeySettings, onOpenKeySettings);
    final retry = onRetry == null ? null : (l10n.commonRetry, onRetry!);
    final (
      IconData icon,
      String message,
      String? description,
      action,
    ) = switch (failure) {
      TransitMissingKey() => (
        Icons.key_outlined,
        l10n.walkTransitMissingKey,
        l10n.walkTransitMissingKeyBody,
        keyAction,
      ),
      TransitKeyRejected() => (
        Icons.key_off_outlined,
        l10n.walkTransitKeyRejected,
        l10n.walkTransitKeyRejectedHint,
        keyAction,
      ),
      TransitQuotaExceeded() => (
        Icons.hourglass_empty_outlined,
        l10n.walkTransitQuota,
        l10n.walkTransitQuotaBody,
        null,
      ),
      TransitNetwork() => (
        Icons.wifi_off_outlined,
        l10n.walkTransitNetwork,
        null,
        retry,
      ),
      TransitNoRoute() => (
        Icons.directions_off_outlined,
        l10n.walkTransitNoRoute,
        null,
        null,
      ),
      TransitTooClose() => (
        Icons.directions_walk_outlined,
        l10n.walkTransitTooClose,
        l10n.walkTransitTooCloseBody,
        null,
      ),
      TransitServer() => (
        Icons.error_outline,
        l10n.walkTransitServer,
        null,
        retry,
      ),
      TransitUnexpected() => (
        Icons.error_outline,
        l10n.walkTransitUnexpected,
        null,
        retry,
      ),
    };
    final placeholder = AppPlaceholder(
      icon: icon,
      message: message,
      description: description,
      actionLabel: action?.$1,
      onAction: action?.$2,
    );
    final detail = failure.detail;
    if (detail.isEmpty) return placeholder;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        placeholder,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: TransitFailureCause(detail),
        ),
      ],
    );
  }
}
