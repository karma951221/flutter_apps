import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/location/entity/day_track.dart';
import '../../../domain/location/entity/map_style.dart';
import '../../../domain/location/entity/record_mode.dart';
import 'entry_pin.dart';

/// 한 기간의 동선 지도 — 이동선 · 머문 곳 원 · 일기 핀.
///
/// 선: 촘촘 구간은 굵고 진하게, 평소 구간은 얇고 옅게(같은 색). [faint] 면(한 달) 모든 선을
/// 옅게 겹쳐 그려 자주 다닌 길이 진해진다.
///
/// 이동선의 좌표 목록은 [track] 인스턴스가 바뀔 때만 다시 만든다 — 한 달 · 긴 스토리는 점이 많고,
/// 시트를 끌거나 칩 상태가 바뀌는 다시 그리기마다 만들면 버벅인다.
///
/// [fitKey] 가 바뀌고(다른 기간) 그릴 좌표가 생기면 카메라를 그 좌표들에 맞춘다. 같은 기간을
/// 다시 읽으면(복귀 · 새로고침) 새 좌표가 화면(시트 위) 밖으로 나갈 때만 다시 맞춘다 — 그 기간에
/// 사용자가 지도를 직접 옮겼거나 [TrackMapState.moveTo] 로 한 점에 갔으면 그대로 둔다.
class TrackMap extends StatefulWidget {
  const TrackMap({
    required this.track,
    required this.spots,
    required this.entries,
    required this.fitKey,
    required this.onOpenEntry,
    this.faint = false,
    this.bottomInset = 0,
    this.style = MapStyle.fallback,
    super.key,
  });

  /// 비어 있으면 선 없이 지도만.
  final DayTrack track;

  /// 원으로 찍을 곳(머문 곳 · 자주 간 곳).
  final List<LatLng> spots;

  /// 핀으로 찍을 일기(좌표 있는 것).
  final List<DiaryEntry> entries;
  final Object fitKey;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final bool faint;

  /// 지도 아래쪽을 덮는 시트 높이. 카메라 맞춤과 출처 표시를 그만큼 위로 올린다.
  final double bottomInset;

  /// 바탕 타일 모양.
  final MapStyle style;

  @override
  State<TrackMap> createState() => TrackMapState();
}

class TrackMapState extends State<TrackMap> {
  /// 좌표가 없을 때 보이는 곳(서울시청)과 줌.
  static const _fallbackCenter = LatLng(37.5665, 126.9780);
  static const _fallbackZoom = 11.0;
  static const _placeZoom = 16.0;

  /// 선 굵기 · 원 크기. 시각 토큰이 아니라 이 지도의 모양이다.
  static const _denseStroke = 5.0;
  static const _normalStroke = 3.0;
  static const _normalAlpha = 0.5;
  static const _faintAlpha = 0.3;
  static const _spotRadius = 7.0;
  static const _spotRing = 2.0;

  final _controller = MapController();

  /// OSM 타일. getIt 에서 받아 테스트가 stub 으로 바꾼다. TileLayer 가 dispose 할 때까지 같은 것을
  /// 쓴다 — build 마다 새로 받으면 바뀐 provider 는 dispose 되지 않는다.
  late final TileProvider _tileProvider = getIt<TileProvider>();

  Object? _fitted;

  /// 마지막 맞춤 뒤 사용자가 지도를 옮겼다(손 · [moveTo]). 그러면 같은 기간에 점이 늘어도 따라가지 않는다.
  bool _userMoved = false;

  /// [_segmentPoints] · [_trackCoordinates] 를 만든 이동선. 같은 인스턴스면 다시 쓴다.
  DayTrack? _memoTrack;
  List<List<LatLng>> _memoSegments = const [];
  List<LatLng> _memoCoordinates = const [];

  void _memoize() {
    final track = widget.track;
    if (identical(track, _memoTrack)) return;
    _memoTrack = track;
    _memoSegments = [
      for (final s in track.segments)
        List.unmodifiable([for (final p in s.points) LatLng(p.lat, p.lng)]),
    ];
    _memoCoordinates = List.unmodifiable([for (final s in _memoSegments) ...s]);
  }

  /// 구간별 선 좌표([DayTrack.segments] 와 같은 순서).
  List<List<LatLng>> get _segmentPoints {
    _memoize();
    return _memoSegments;
  }

  /// 이동선의 모든 좌표.
  List<LatLng> get _trackCoordinates {
    _memoize();
    return _memoCoordinates;
  }

  @override
  void initState() {
    super.initState();
    if (_coordinates().isNotEmpty) _fitted = widget.fitKey;
  }

  @override
  void didUpdateWidget(TrackMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final coordinates = _coordinates();
    if (coordinates.isEmpty) return;
    if (widget.fitKey != _fitted) {
      _fitted = widget.fitKey;
      // 빌드 중에 카메라를 옮기지 않는다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit(coordinates);
      });
      return;
    }
    if (_userMoved || !_sourcesChanged(oldWidget)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_userMoved && !_allVisible(coordinates)) {
        _fit(coordinates);
      }
    });
  }

  bool _sourcesChanged(TrackMap old) =>
      !identical(old.track, widget.track) ||
      !identical(old.entries, widget.entries);

  /// 모든 좌표가 시트에 가리지 않은 화면 안에 있나.
  bool _allVisible(List<LatLng> coordinates) {
    final camera = _controller.camera;
    final size = camera.nonRotatedSize;
    final bottom = size.height - widget.bottomInset;
    return coordinates.every((p) {
      final o = camera.latLngToScreenOffset(p);
      return o.dx >= 0 && o.dx <= size.width && o.dy >= 0 && o.dy <= bottom;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 지도를 한 점으로 옮긴다(타임라인 · 자주 간 곳 행).
  void moveTo(double lat, double lng) {
    _userMoved = true;
    _controller.move(
      LatLng(lat, lng),
      math.max(_controller.camera.zoom, _placeZoom),
    );
  }

  List<LatLng> _coordinates() => [
    ..._trackCoordinates,
    ...widget.spots,
    for (final e in widget.entries)
      if (e.location case final l? when l.hasCoordinates)
        LatLng(l.lat!, l.lng!),
  ];

  EdgeInsets get _fitPadding => const EdgeInsets.all(
    AppSpacing.xl,
  ).copyWith(bottom: AppSpacing.xl + widget.bottomInset);

  void _fit(List<LatLng> coordinates) {
    _userMoved = false;
    if (_isSinglePlace(coordinates)) {
      _controller.move(coordinates.first, _placeZoom);
    } else {
      _controller.fitCamera(
        CameraFit.coordinates(coordinates: coordinates, padding: _fitPadding),
      );
    }
  }

  /// 단순 · 기본 · 어둡게는 OSM 기본 타일 하나 — 차이는 [_tileBuilderOf] 의 색 필터뿐이라 바꿔도
  /// 타일을 다시 받지 않는다.
  static const _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// 지형: OpenTopoMap(자원봉사 서버, 최대 줌 17).
  static const _terrainUrl = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  static const _terrainSubdomains = ['a', 'b', 'c'];

  /// 위성: Esri World Imagery. 서울은 줌 18까지 선명하다. 주소의 순서가 z/y/x 다.
  static const _satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  static String _urlOf(MapStyle style) => switch (style) {
    MapStyle.simple || MapStyle.standard || MapStyle.dark => _osmUrl,
    MapStyle.terrain => _terrainUrl,
    MapStyle.satellite => _satelliteUrl,
  };

  /// 타일 서버가 가진 가장 큰 줌. 더 들어가면 이 줌 타일을 키워 그린다(빈 타일 대신).
  static int _maxNativeZoomOf(MapStyle style) => switch (style) {
    MapStyle.terrain => 17,
    MapStyle.satellite => 18,
    MapStyle.simple || MapStyle.standard || MapStyle.dark => 19,
  };

  /// 앞에 © 가 붙는다. 좁은 폰에서 한 줄에 들어가게 짧게.
  static String _attributionOf(MapStyle style) => switch (style) {
    MapStyle.simple ||
    MapStyle.standard ||
    MapStyle.dark => 'OpenStreetMap contributors',
    MapStyle.terrain => 'OpenStreetMap · OpenTopoMap (CC-BY-SA)',
    MapStyle.satellite => 'Esri · Maxar · Earthstar Geographics',
  };

  /// 단순: 채도를 30% 로 줄이고 흰색과 35% 섞는다. 지도 위 동선 색이 바탕보다 진해 보이게.
  static final _simpleFilter = ColorFilter.matrix(_mutedMatrix(0.3, 0.35));

  /// 채도 [s](0 = 회색) 로 줄인 뒤 흰색과 [white] 만큼 섞는 색 행렬.
  static List<double> _mutedMatrix(double s, double white) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final k = 1 - white;
    final offset = 255 * white;
    List<double> row(double r, double g, double b) => [
      k * r,
      k * g,
      k * b,
      0,
      offset,
    ];
    return [
      ...row(lr * (1 - s) + s, lg * (1 - s), lb * (1 - s)),
      ...row(lr * (1 - s), lg * (1 - s) + s, lb * (1 - s)),
      ...row(lr * (1 - s), lg * (1 - s), lb * (1 - s) + s),
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// 어둡게: 회색으로 바꾼 뒤 밝기를 뒤집고(×0.8) 조금 띄운다. flutter_map 의 반전 + 색상 회전은
  /// 큰길이 갈색으로 남아 탁했다.
  static const _darkFilter = ColorFilter.matrix(<double>[
    -0.8 * 0.2126, -0.8 * 0.7152, -0.8 * 0.0722, 0, 0.8 * 255 + 12, //
    -0.8 * 0.2126, -0.8 * 0.7152, -0.8 * 0.0722, 0, 0.8 * 255 + 12, //
    -0.8 * 0.2126, -0.8 * 0.7152, -0.8 * 0.0722, 0, 0.8 * 255 + 12, //
    0, 0, 0, 1, 0,
  ]);

  static Widget _darkTileBuilder(
    BuildContext context,
    Widget tile,
    TileImage image,
  ) => ColorFiltered(colorFilter: _darkFilter, child: tile);

  static Widget _simpleTileBuilder(
    BuildContext context,
    Widget tile,
    TileImage image,
  ) => ColorFiltered(colorFilter: _simpleFilter, child: tile);

  /// 단순 · 어둡게만 필터를 씌운다.
  static TileBuilder? _tileBuilderOf(MapStyle style) => switch (style) {
    MapStyle.simple => _simpleTileBuilder,
    MapStyle.dark => _darkTileBuilder,
    MapStyle.standard || MapStyle.terrain || MapStyle.satellite => null,
  };

  static bool _isSinglePlace(List<LatLng> c) => c.every((p) => p == c.first);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coordinates = _coordinates();
    final single = coordinates.isNotEmpty && _isSinglePlace(coordinates);
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: coordinates.firstOrNull ?? _fallbackCenter,
        initialZoom: coordinates.isEmpty ? _fallbackZoom : _placeZoom,
        initialCameraFit: coordinates.isEmpty || single
            ? null
            : CameraFit.coordinates(
                coordinates: coordinates,
                padding: _fitPadding,
              ),
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) _userMoved = true;
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // key 를 바꾸지 않는다 — 새 TileLayer 가 되면 옛것이 _tileProvider 를 dispose 한다.
        // URL 이 바뀌면 TileLayer 가 스스로 타일을 다시 읽는다.
        TileLayer(
          urlTemplate: _urlOf(widget.style),
          subdomains: widget.style == MapStyle.terrain
              ? _terrainSubdomains
              : const [],
          maxNativeZoom: _maxNativeZoomOf(widget.style),
          userAgentPackageName: 'com.karma.walk',
          tileProvider: _tileProvider,
          tileBuilder: _tileBuilderOf(widget.style),
        ),
        PolylineLayer(
          polylines: [
            for (final (i, s) in widget.track.segments.indexed)
              if (s.points.length > 1)
                Polyline(
                  points: _segmentPoints[i],
                  strokeWidth: !widget.faint && s.mode == RecordMode.dense
                      ? _denseStroke
                      : _normalStroke,
                  color: scheme.primary.withValues(
                    alpha: widget.faint
                        ? _faintAlpha
                        : s.mode == RecordMode.dense
                        ? 1
                        : _normalAlpha,
                  ),
                  strokeCap: StrokeCap.round,
                  strokeJoin: StrokeJoin.round,
                ),
          ],
        ),
        CircleLayer(
          circles: [
            for (final spot in widget.spots)
              CircleMarker(
                point: spot,
                radius: _spotRadius,
                color: scheme.primary,
                borderColor: scheme.surface,
                borderStrokeWidth: _spotRing,
              ),
          ],
        ),
        EntryPinLayer(entries: widget.entries, onOpen: widget.onOpenEntry),
        Padding(
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          child: SimpleAttributionWidget(
            source: Text(_attributionOf(widget.style)),
          ),
        ),
      ],
    );
  }
}
