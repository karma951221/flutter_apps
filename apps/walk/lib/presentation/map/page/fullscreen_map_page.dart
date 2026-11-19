import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide DayPeriod;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/location/entity/day_track.dart';
import '../../../domain/location/entity/map_period.dart';
import '../../diary/page/diary_route.dart';
import '../cubit/map_style_cubit.dart';
import '../cubit/map_view_cubit.dart';
import '../cubit/map_view_state.dart';
import '../widget/track_map.dart';

/// 지도 위 원 자리 — 한 달은 자주 간 곳, 하루 · 스토리는 머문 곳.
List<LatLng> mapSpotsOf(MapViewData data) => switch (data.period) {
  MonthPeriod() => [for (final f in data.frequent) LatLng(f.lat, f.lng)],
  DayPeriod() ||
  StoryPeriod() => [for (final s in data.track.stays) LatLng(s.lat, s.lng)],
};

/// 지도를 전체화면으로 연다. 셸의 탭바 · 기간 머리 · 아래 시트 · 기록 표시 없이 지도와 나가기
/// 버튼만 두고, 시스템 바도 숨긴다(몰입 모드). [camera] 자리에서 열고, 나갈 때(버튼 · 뒤로가기)
/// 마지막 카메라를 돌려준다 — 지도 탭이 그 자리로 옮겨 이어 본다. 잠기면 null.
///
/// 일기 잠금 아래([pushDiaryRoute])다. 지도 탭의 [MapViewCubit] 을 이어 보아 기록이 늘면 따라 그린다.
Future<MapCameraSpot?> openFullscreenMap(
  BuildContext context, {
  required MapCameraSpot camera,
  required MapStyleCubit style,
  required void Function(MapViewData data, DiaryEntry entry) onOpenEntry,
}) {
  final view = context.read<MapViewCubit>();
  return pushDiaryRoute<MapCameraSpot>(
    context,
    fade: true,
    scope: (_, gated) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: view),
        BlocProvider.value(value: style),
      ],
      child: gated,
    ),
    page: (_) => FullscreenMapPage(camera: camera, onOpenEntry: onOpenEntry),
  );
}

class FullscreenMapPage extends StatefulWidget {
  const FullscreenMapPage({
    required this.camera,
    required this.onOpenEntry,
    super.key,
  });

  final MapCameraSpot camera;
  final void Function(MapViewData data, DiaryEntry entry) onOpenEntry;

  @override
  State<FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<FullscreenMapPage> {
  final _map = GlobalKey<TrackMapState>();

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  MapCameraSpot get _camera => _map.currentState?.camera ?? widget.camera;

  void _exit() => Navigator.of(context).pop(_camera);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = context.watch<MapViewCubit>().state;
    final style = context.watch<MapStyleCubit>().state;
    final data = switch (view) {
      MapViewReady(:final data) => data,
      _ => null,
    };
    return PopScope<MapCameraSpot>(
      // 뒤로가기도 카메라를 들고 나간다.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: TrackMap(
                key: _map,
                track: data?.track ?? const DayTrack(segments: [], stays: []),
                spots: data == null ? const [] : mapSpotsOf(data),
                entries: data?.entries ?? const [],
                fitKey: data?.period ?? const Object(),
                faint: data?.period is MonthPeriod,
                style: style,
                initialCamera: widget.camera,
                onOpenEntry: (entry) {
                  if (data != null) widget.onOpenEntry(data, entry);
                },
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: SafeArea(
                child: IconButton.filledTonal(
                  key: const Key('map-fullscreen-exit'),
                  tooltip: l10n.walkMapFullscreenExit,
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed: _exit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
