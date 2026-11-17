import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/entity/transit_point.dart';

/// 지점 이름. 저장된 이름이 없으면(현재 위치 · 이름 못 얻은 자주 간 곳 등) 종류로 대신한다.
String transitPointLabel(AppLocalizations l10n, TransitPoint point) {
  if (point.source == TransitPointSource.currentLocation) {
    return l10n.walkTransitCurrentLocation;
  }
  if (point.label.trim().isNotEmpty) return point.label;
  return switch (point.source) {
    TransitPointSource.currentLocation => l10n.walkTransitCurrentLocation,
    TransitPointSource.home => l10n.walkTransitHome,
    TransitPointSource.work => l10n.walkTransitWork,
    TransitPointSource.frequent => l10n.walkTransitFrequent,
    TransitPointSource.recent ||
    TransitPointSource.station ||
    TransitPointSource.address => l10n.walkTransitPlaceFallback,
  };
}

/// 출발 · 도착 두 칸과 바꾸기 버튼. 칸을 누르면 장소 고르기를 연다.
class PointFields extends StatelessWidget {
  const PointFields({
    required this.from,
    required this.to,
    required this.locating,
    required this.locationFailed,
    required this.onTapFrom,
    required this.onTapTo,
    required this.onSwap,
    super.key,
  });

  final TransitPoint? from;
  final TransitPoint? to;

  /// 출발을 현재 위치로 채우는 중.
  final bool locating;

  /// 현재 위치를 얻지 못해 출발이 비어 있다.
  final bool locationFailed;

  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final from = this.from;
    final to = this.to;
    final fromHint = locating
        ? l10n.walkTransitLocating
        : locationFailed
        ? l10n.walkTransitLocationFailed
        : l10n.walkTransitPickHint;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _Field(
                key: const Key('transit-from'),
                caption: l10n.walkTransitFrom,
                dotColor: scheme.primary,
                value: from == null ? null : transitPointLabel(l10n, from),
                hint: fromHint,
                warn: from == null && locationFailed,
                onTap: onTapFrom,
              ),
              _Field(
                key: const Key('transit-to'),
                caption: l10n.walkTransitTo,
                dotColor: scheme.tertiary,
                value: to == null ? null : transitPointLabel(l10n, to),
                hint: l10n.walkTransitPickHint,
                warn: false,
                onTap: onTapTo,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.walkTransitSwap,
          onPressed: from == null && to == null ? null : onSwap,
          icon: const Icon(Icons.swap_vert),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.caption,
    required this.dotColor,
    required this.value,
    required this.hint,
    required this.warn,
    required this.onTap,
    super.key,
  });

  final String caption;
  final Color dotColor;
  final String? value;
  final String hint;
  final bool warn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = this.value;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.circle,
              size: theme.textTheme.labelSmall?.fontSize,
              color: dotColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              caption,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: value != null
                    ? theme.textTheme.bodyLarge
                    : theme.textTheme.bodyLarge?.copyWith(
                        color: warn ? scheme.error : scheme.onSurfaceVariant,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
