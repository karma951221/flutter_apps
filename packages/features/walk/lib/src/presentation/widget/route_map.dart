import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entity/geo_point.dart';

/// 경로 지도. W2 진행 화면(`follow`)과 W3 상세가 함께 쓴다.
///
/// 점이 없으면 지도를 그리지 않고 [emptyMessage] 안내를 보인다.
class RouteMap extends StatefulWidget {
  const RouteMap({
    required this.points,
    this.follow = false,
    this.emptyMessage,
    this.tileProvider,
    super.key,
  });

  final List<GeoPoint> points;

  /// 켜면 마지막 점이 바뀔 때 지도 중심을 그 점으로 옮긴다(줌 유지).
  final bool follow;
  final String? emptyMessage;

  /// null 이면 `getIt<TileProvider>()`. 테스트가 stub 으로 바꾼다.
  final TileProvider? tileProvider;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  static const _singlePointZoom = 17.0;

  final _controller = MapController();

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final last = widget.points.lastOrNull;
    // 이전에 점이 없었다면 지도가 아직 없었다 — 새로 만들어질 때 초기 카메라를 쓴다.
    if (widget.follow &&
        last != null &&
        oldWidget.points.isNotEmpty &&
        last != oldWidget.points.last) {
      _controller.move(_latLng(last), _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LatLng _latLng(GeoPoint p) => LatLng(p.lat, p.lng);

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    if (points.isEmpty) {
      return Center(child: AppPlaceholder(message: widget.emptyMessage ?? ''));
    }

    final scheme = Theme.of(context).colorScheme;
    final latLngs = [for (final p in points) _latLng(p)];
    final isSinglePlace = latLngs.every((p) => p == latLngs.first);

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: latLngs.last,
        initialZoom: _singlePointZoom,
        initialCameraFit: isSinglePlace
            ? null
            : CameraFit.coordinates(
                coordinates: latLngs,
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.karma.pawlog',
          tileProvider: widget.tileProvider ?? getIt<TileProvider>(),
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: latLngs,
              strokeWidth: AppSpacing.xs,
              color: scheme.primary,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: latLngs.first,
              width: AppSpacing.lg,
              height: AppSpacing.lg,
              child: Icon(
                Icons.circle,
                size: AppSpacing.md,
                color: scheme.primary,
              ),
            ),
            if (!isSinglePlace)
              Marker(
                point: latLngs.last,
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                child: Icon(
                  Icons.location_on,
                  size: AppSpacing.xl,
                  color: scheme.tertiary,
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
