import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/walk/entity/geo_point.dart';
import '../../theme/pawlog_theme.dart';
import 'route_draw.dart';

/// 경로 지도. W2 진행 화면(`follow`)과 W3 상세가 함께 쓴다.
///
/// 점이 없으면 지도를 그리지 않고 [emptyMessage] 안내를 보인다.
class RouteMap extends StatefulWidget {
  const RouteMap({
    required this.points,
    this.follow = false,
    this.emptyMessage,
    this.tileProvider,
    this.animateDraw = false,
    this.bottomInset = 0,
    super.key,
  });

  /// 지도 아래쪽이 다른 면(진행 화면 시트의 둥근 모서리)에 덮이는 높이. 출처 표시와
  /// 처음 경로 맞춤을 그만큼 위로 올린다 — OSM 타일은 출처가 보여야 한다.
  final double bottomInset;

  /// 켜면 처음 보일 때 선이 출발점부터 1.6초에 걸쳐 그려진다(상세 화면). 애니메이션
  /// 줄이기가 켜져 있으면 바로 완성된 선이다.
  final bool animateDraw;

  /// [points] 의 출발점부터 전체 길이의 [fraction] 까지 — 마지막 구간은 중간에서 끊는다.
  @visibleForTesting
  static List<LatLng> partialRoute(List<LatLng> points, double fraction) {
    if (fraction >= 1 || points.length < 2) return points;
    if (fraction <= 0) return [points.first];
    // 짧은 산책 경로라 평면 근사로 충분하다. 경도는 위도에 따라 짧아진다.
    final lngScale = math.cos(points.first.latitude * math.pi / 180);
    double length(LatLng a, LatLng b) {
      final dLat = b.latitude - a.latitude;
      final dLng = (b.longitude - a.longitude) * lngScale;
      return math.sqrt(dLat * dLat + dLng * dLng);
    }

    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += length(points[i - 1], points[i]);
    }
    var remaining = total * fraction;
    final head = [points.first];
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segment = length(a, b);
      if (segment >= remaining) {
        final t = segment == 0 ? 1.0 : remaining / segment;
        head.add(
          LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          ),
        );
        return head;
      }
      head.add(b);
      remaining -= segment;
    }
    return head;
  }

  final List<GeoPoint> points;

  /// 켜면 마지막 점이 바뀔 때 지도 중심을 그 점으로 옮긴다(줌 유지).
  final bool follow;
  final String? emptyMessage;

  /// null 이면 `getIt<TileProvider>()` 로 지도마다 하나 받는다. 테스트가 stub 으로 바꾼다.
  final TileProvider? tileProvider;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  static const _singlePointZoom = 17.0;

  final _controller = MapController();

  /// TileLayer 가 dispose 할 때까지 같은 것을 쓴다 — build 마다 새로 받으면
  /// 바뀐 provider 는 dispose 되지 않는다.
  late final TileProvider _tileProvider =
      widget.tileProvider ?? getIt<TileProvider>();

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

    final colors = PawlogColors.of(context);
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
                padding: const EdgeInsets.all(
                  PawlogSpacing.xl,
                ).copyWith(bottom: PawlogSpacing.xl + widget.bottomInset),
              ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.karma.pawlog',
          tileProvider: _tileProvider,
        ),
        // 남색 테두리 9 위에 연두 5, 둥근 끝 · 둥근 이음(design.md 경로 선).
        RouteDraw(
          animate: widget.animateDraw,
          builder: (context, progress) {
            final drawn = RouteMap.partialRoute(latLngs, progress);
            return Stack(
              fit: StackFit.expand,
              children: [
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: drawn,
                      strokeWidth: PawlogSize.routeStroke,
                      color: colors.accent,
                      borderStrokeWidth:
                          PawlogSize.routeCasing - PawlogSize.routeStroke,
                      borderColor: colors.routeCasing,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLngs.first,
                      width: PawlogSize.routeMarker,
                      height: PawlogSize.routeMarker,
                      child: _Dot(
                        fill: colors.routeCasing,
                        ring: colors.onPrimary,
                      ),
                    ),
                    // 도착 점은 선이 거기 닿은 뒤에 나타난다.
                    if (!isSinglePlace && progress >= 1)
                      Marker(
                        point: latLngs.last,
                        width: PawlogSize.routeMarker,
                        height: PawlogSize.routeMarker,
                        child: _Dot(
                          fill: colors.accent,
                          ring: colors.routeCasing,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        Padding(
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          child: const SimpleAttributionWidget(
            source: Text('OpenStreetMap contributors'),
          ),
        ),
      ],
    );
  }
}

/// 출발(남색) · 현재 또는 도착(연두) 점. 핀 아이콘 대신 선과 같은 두 색만 쓴다.
class _Dot extends StatelessWidget {
  const _Dot({required this.fill, required this.ring});

  final Color fill;
  final Color ring;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: fill,
      shape: BoxShape.circle,
      border: Border.all(color: ring, width: PawlogSize.avatarRing),
    ),
  );
}
