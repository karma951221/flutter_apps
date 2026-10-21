import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/commute/entity/commute_direction.dart';
import '../../../domain/commute/entity/place.dart';

/// "집 동작구 … → 회사 강남구 …". 방향에 따라 출발 장소가 앞에 온다.
/// 각 장소를 누르면 [onEditPlace] 로 그 장소 종류를 알린다.
class PlaceRow extends StatelessWidget {
  const PlaceRow({
    required this.direction,
    required this.home,
    required this.work,
    this.onEditPlace,
    super.key,
  });

  final CommuteDirection direction;
  final Place? home;
  final Place? work;
  final ValueChanged<PlaceKind>? onEditPlace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _slot(context, direction.origin)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(child: _slot(context, direction.destination)),
      ],
    );
  }

  Widget _slot(BuildContext context, PlaceKind kind) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final place = switch (kind) {
      PlaceKind.home => home,
      PlaceKind.work => work,
    };
    final name = switch (kind) {
      PlaceKind.home => l10n.walkCommutePlaceHome,
      PlaceKind.work => l10n.walkCommutePlaceWork,
    };
    return InkWell(
      key: Key('commute-place-${kind.name}'),
      borderRadius: AppRadius.smAll,
      onTap: () => onEditPlace?.call(kind),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.labelMedium),
            Text(
              place?.label ?? l10n.walkCommutePlaceUnset,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: place == null ? theme.colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
