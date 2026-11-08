import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/stay.dart';
import '../../../domain/location/geo/geo_math.dart';

/// 머문 시간 표기 — `45분` · `8시간` · `1시간 20분`.
String formatStayDuration(AppLocalizations l10n, Duration d) {
  final minutes = d.inMinutes.remainder(60);
  if (d.inHours == 0) return l10n.walkMapDurationMinutes(d.inMinutes);
  if (minutes == 0) return l10n.walkMapDurationHours(d.inHours);
  return l10n.walkMapDurationHoursMinutes(d.inHours, minutes);
}

/// 지도 아래에서 끌어올리는 시트의 틀 — 손잡이 · 제목 · 행들. 부모 `Stack` 을 채운다.
///
/// 시트 바깥(위쪽 지도)은 터치를 지도에 그대로 넘긴다.
class MapSheet extends StatelessWidget {
  const MapSheet({
    required this.title,
    required this.children,
    required this.emptyMessage,
    super.key,
  });

  static const minSize = 0.12;
  static const initialSize = 0.3;
  static const maxSize = 0.8;

  /// 손잡이 크기. 시각 토큰이 아니라 이 위젯의 모양이다.
  static const _handleWidth = 32.0;
  static const _handleHeight = 4.0;

  final String title;
  final List<Widget> children;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DraggableScrollableSheet(
      minChildSize: minSize,
      initialChildSize: initialSize,
      maxChildSize: maxSize,
      snap: true,
      builder: (context, controller) => Material(
        color: scheme.surfaceContainerLow,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const SizedBox(
                    width: _handleWidth,
                    height: _handleHeight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  emptyMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

/// 하루 · 스토리 보기의 시간순 머문 곳. 행을 누르면 [onTap] — 지도가 그 점으로 간다.
class TimelineSheet extends StatelessWidget {
  const TimelineSheet({
    required this.stays,
    required this.names,
    required this.onTap,
    this.showDate = false,
    super.key,
  });

  final List<Stay> stays;

  /// `gridKey` → 이름.
  final Map<String, String> names;
  final ValueChanged<Stay> onTap;

  /// 여러 날에 걸친 보기(스토리)면 시각 앞에 날짜를 붙인다.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = showDate
        ? DateFormat.MMMd(l10n.localeName).add_Hm()
        : DateFormat.Hm(l10n.localeName);
    final sorted = [...stays]..sort((a, b) => a.start.compareTo(b.start));
    return MapSheet(
      title: l10n.walkMapTimelineTitle,
      emptyMessage: l10n.walkMapTimelineEmpty,
      children: [
        for (final stay in sorted)
          AppListTile(
            leading: Text(time.format(stay.start.toLocal())),
            title: Text(
              names[gridKey(stay.lat, stay.lng)] ?? l10n.walkMapUnnamedPlace,
            ),
            subtitle: Text(formatStayDuration(l10n, stay.duration)),
            onTap: () => onTap(stay),
          ),
      ],
    );
  }
}
