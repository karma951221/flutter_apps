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

  /// CARTO basemap 은 OSM 데이터 위에 그린 무료 타일이다(출처 둘 다 표시).
  static const _cartoSubdomains = ['a', 'b', 'c', 'd'];

  static String _urlOf(MapStyle style) => switch (style) {
    MapStyle.standard => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    MapStyle.simple =>
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
    MapStyle.plain =>
      'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
    MapStyle.dark =>
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
  };

  static String _attributionOf(MapStyle style) => switch (style) {
    MapStyle.standard => 'OpenStreetMap contributors',
    MapStyle.simple ||
    MapStyle.plain ||
    MapStyle.dark => 'OpenStreetMap contributors · CARTO',
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
          subdomains: widget.style == MapStyle.standard
              ? const []
              : _cartoSubdomains,
          userAgentPackageName: 'com.karma.walk',
          tileProvider: _tileProvider,
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
