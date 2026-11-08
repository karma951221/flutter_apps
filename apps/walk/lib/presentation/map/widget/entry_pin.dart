import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:l10n/l10n.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/diary/entity/diary_entry.dart';
import '../../diary/widget/entry_media_view.dart';

/// 화면에서 [radius] 픽셀 안에 드는 것끼리 묶는다(탐욕적 — 앞에서부터 첫 묶음의 대표와 비교).
/// 묶음의 첫 원소가 대표다. 순서는 들어온 순서를 따른다.
List<List<T>> clusterByDistance<T>(
  List<T> items,
  Offset Function(T item) project, {
  required double radius,
}) {
  final clusters = <({Offset at, List<T> items})>[];
  for (final item in items) {
    final at = project(item);
    final near = clusters
        .where((c) => (c.at - at).distance <= radius)
        .firstOrNull;
    if (near == null) {
      clusters.add((at: at, items: [item]));
    } else {
      near.items.add(item);
    }
  }
  return [for (final c in clusters) c.items];
}

/// 지도 위 일기 핀. `FlutterMap` 의 자식이어야 한다 — 지금 카메라로 같은 자리 핀을 묶는다.
///
/// 묶음은 이른 기록이 대표다. 누르면 [onOpen] 에 대표 기록을 넘긴다.
class EntryPinLayer extends StatelessWidget {
  const EntryPinLayer({required this.entries, required this.onOpen, super.key});

  /// 좌표가 있는 기록들.
  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpen;

  /// 핀 크기. 시각 토큰이 아니라 이 위젯의 크기다.
  static const pinSize = 40.0;

  /// 묶음 숫자 배지가 핀 밖으로 조금 나간다 — 마커는 그만큼 크게 잡는다.
  static const _markerSize = pinSize + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final sorted = [
      for (final e in entries)
        if (e.location?.hasCoordinates ?? false) e,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final clusters = clusterByDistance(
      sorted,
      (e) => camera.projectAtZoom(_latLng(e)),
      radius: pinSize,
    );
    return MarkerLayer(
      markers: [
        for (final group in clusters)
          Marker(
            point: _latLng(group.first),
            width: _markerSize,
            height: _markerSize,
            child: EntryPin(
              entry: group.first,
              count: group.length,
              onTap: () => onOpen(group.first),
            ),
          ),
      ],
    );
  }

  static LatLng _latLng(DiaryEntry e) =>
      LatLng(e.location!.lat!, e.location!.lng!);
}

/// 핀 하나. 사진 · 영상이 있으면 첫 미디어 썸네일, 없으면 일반 핀. [count] 가 2 이상이면
/// 숫자 배지를 단다.
class EntryPin extends StatelessWidget {
  const EntryPin({
    required this.entry,
    required this.count,
    required this.onTap,
    super.key,
  });

  final DiaryEntry entry;
  final int count;
  final VoidCallback onTap;

  /// 핀 테두리 두께. 시각 토큰이 아니라 이 위젯의 모양이다.
  static const _ring = 2.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = entry.media.firstOrNull;
    const size = EntryPinLayer.pinSize;
    final Widget face = media == null
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: _ring),
            ),
            child: SizedBox.square(
              dimension: size,
              child: Icon(Icons.edit_note, color: scheme.onPrimary),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: scheme.surface, width: _ring),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: SizedBox.square(
                dimension: size,
                child: EntryMediaView(media: media),
              ),
            ),
          );
    return Center(
      child: Semantics(
        button: true,
        label: AppLocalizations.of(context).walkMapPinCount(count),
        child: GestureDetector(
          key: ValueKey('map-pin-${entry.id}'),
          onTap: onTap,
          child: count > 1 ? Badge(label: Text('$count'), child: face) : face,
        ),
      ),
    );
  }
}
