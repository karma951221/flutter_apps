import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/location/entity/map_style.dart';

/// 지도 종류를 고르는 시트. 고른 모양 또는 null.
Future<MapStyle?> showMapStyleSheet(
  BuildContext context, {
  required MapStyle current,
}) => showAppSheet<MapStyle>(
  context: context,
  builder: (_) => _MapStyleSheet(current: current),
);

String mapStyleLabel(AppLocalizations l10n, MapStyle style) => switch (style) {
  MapStyle.simple => l10n.walkMapStyleSimple,
  MapStyle.standard => l10n.walkMapStyleStandard,
  MapStyle.terrain => l10n.walkMapStyleTerrain,
  MapStyle.satellite => l10n.walkMapStyleSatellite,
  MapStyle.dark => l10n.walkMapStyleDark,
};

String _detail(AppLocalizations l10n, MapStyle style) => switch (style) {
  MapStyle.simple => l10n.walkMapStyleSimpleDetail,
  MapStyle.standard => l10n.walkMapStyleStandardDetail,
  MapStyle.terrain => l10n.walkMapStyleTerrainDetail,
  MapStyle.satellite => l10n.walkMapStyleSatelliteDetail,
  MapStyle.dark => l10n.walkMapStyleDarkDetail,
};

class _MapStyleSheet extends StatelessWidget {
  const _MapStyleSheet({required this.current});

  final MapStyle current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppSheetScaffold(
      title: l10n.walkMapStyle,
      children: [
        for (final style in MapStyle.values)
          AppSelectTile(
            key: Key('map-style-${style.name}'),
            title: Text(mapStyleLabel(l10n, style)),
            subtitle: Text(_detail(l10n, style)),
            selected: style == current,
            onTap: () => Navigator.pop(context, style),
          ),
      ],
    );
  }
}
