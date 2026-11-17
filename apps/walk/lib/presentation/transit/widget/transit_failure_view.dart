import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/transit_failure.dart';

/// 길찾기 실패 안내. 키 없음 · 키 거부는 [onOpenKeySettings], 네트워크 · 서버 오류는 [onRetry] 버튼.
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
      TransitKeyRejected(:final message) => (
        Icons.key_off_outlined,
        l10n.walkTransitKeyRejected,
        message.isEmpty ? null : message,
        keyAction,
      ),
      TransitQuotaExceeded() => (
        Icons.hourglass_empty,
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
        Icons.directions_walk,
        l10n.walkTransitTooClose,
        l10n.walkTransitTooCloseBody,
        null,
      ),
      TransitServer(:final message) => (
        Icons.error_outline,
        l10n.walkTransitServer,
        message.isEmpty ? null : message,
        retry,
      ),
    };
    return AppPlaceholder(
      icon: icon,
      message: message,
      description: description,
      actionLabel: action?.$1,
      onAction: action?.$2,
    );
  }
}
