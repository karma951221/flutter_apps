import 'dart:math' as math;

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
/// 핀은 사진 없이 개수(하나면 작은 점)만 보인다. 누르면 [onSelect] 에 묶음 대표(이른 기록) id 를
/// 넘기고, [selected] 인 묶음 위에 정사각 사진 미리보기 띠를 띄운다. 띠의 칸을 누르면 [onOpen] 에
/// 그 기록을 넘긴다. 열린 핀을 다시 누르면 [onSelect] 에 null 을 넘긴다(닫기).
///
/// 줌이 바뀌어 묶음이 달라져도 [selected] 기록이 든 묶음에 미리보기가 붙는다.
class EntryPinLayer extends StatelessWidget {
  const EntryPinLayer({
    required this.entries,
    required this.onOpen,
    this.selected,
    this.onSelect,
    super.key,
  });

  /// 좌표가 있는 기록들.
  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpen;

  /// 미리보기를 띄운 묶음의 기록 id(대표가 아니어도 된다).
  final String? selected;
  final ValueChanged<String?>? onSelect;

  /// 핀이 받는 탭 영역. 시각 토큰이 아니라 이 위젯의 크기다.
  static const pinSize = 40.0;

  /// 미리보기 칸 한 변 · 한 번에 보이는 칸 수. 넘치면 띠가 옆으로 스크롤된다.
  static const previewSize = 64.0;
  static const _previewVisible = 4;

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
    final open = selected == null
        ? null
        : clusters.where((c) => c.any((e) => e.id == selected)).firstOrNull;
    final visible = math.min(open?.length ?? 0, _previewVisible);
    const previewHeight = previewSize + AppSpacing.xs * 2 + pinSize / 2;
    // 핀이 지도 위쪽 끝에 붙어 있으면 띠가 지도 밖(머리 밑)으로 나간다 — 아래로 띄운다.
    final below =
        open != null &&
        camera.latLngToScreenOffset(_latLng(open.first)).dy < previewHeight;
    return MarkerLayer(
      markers: [
        for (final group in clusters)
          Marker(
            point: _latLng(group.first),
            width: pinSize,
            height: pinSize,
            child: EntryPin(
              entry: group.first,
              count: group.length,
              selected: identical(group, open),
              onTap: () => onSelect?.call(
                identical(group, open) ? null : group.first.id,
              ),
            ),
          ),
        // 핀보다 뒤에 두어 위에 그린다. 핀 위쪽(자리가 없으면 아래쪽)에 붙는다.
        if (open != null)
          Marker(
            point: _latLng(open.first),
            alignment: below ? Alignment.bottomCenter : Alignment.topCenter,
            width: visible * (previewSize + AppSpacing.xs) + AppSpacing.xs,
            height: previewHeight,
            child: Padding(
              padding: below
                  ? const EdgeInsets.only(top: pinSize / 2)
                  : const EdgeInsets.only(bottom: pinSize / 2),
              child: EntryPinPreview(entries: open, onOpen: onOpen),
            ),
          ),
      ],
    );
  }

  static LatLng _latLng(DiaryEntry e) =>
      LatLng(e.location!.lat!, e.location!.lng!);
}

/// 핀 하나 — 사진 없이 개수 배지. [count] 가 1 이면 작은 점에 사진 · 글 아이콘.
class EntryPin extends StatelessWidget {
  const EntryPin({
    required this.entry,
    required this.count,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final DiaryEntry entry;
  final int count;
  final VoidCallback onTap;

  /// 미리보기가 열린 핀 — 색을 뒤집어 어느 핀의 것인지 보인다.
  final bool selected;

  /// 배지 · 점 크기와 테두리. 시각 토큰이 아니라 이 위젯의 모양이다.
  static const _badge = 28.0;
  static const _dot = 22.0;
  static const _dotIcon = 14.0;
  static const _ring = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = selected ? scheme.onPrimary : scheme.primary;
    final ink = selected ? scheme.primary : scheme.onPrimary;
    final single = count == 1;
    final face = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.surface,
          width: _ring,
        ),
      ),
      child: SizedBox.square(
        dimension: single ? _dot : _badge,
        child: Center(
          child: single
              ? Icon(
                  entry.media.isEmpty ? Icons.edit_note : Icons.photo,
                  size: _dotIcon,
                  color: ink,
                )
              : Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(color: ink),
                ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).walkMapPinCount(count),
      child: GestureDetector(
        key: ValueKey('map-pin-${entry.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(child: face),
      ),
    );
  }
}

/// 핀 위 미리보기 띠 — 정사각 사진(글 기록은 글 첫 줄) 칸. 칸을 누르면 [onOpen].
class EntryPinPreview extends StatelessWidget {
  const EntryPinPreview({
    required this.entries,
    required this.onOpen,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpen;

  /// 지도 위에 뜬 띠의 그림자 높이. 시각 토큰이 아니라 이 위젯의 모양이다.
  static const _elevation = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: _elevation,
      borderRadius: AppRadius.smAll,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.xs / 2),
        child: Row(
          children: [
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs / 2),
                child: _PreviewTile(entry: e, onTap: () => onOpen(e)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.entry, required this.onTap});

  final DiaryEntry entry;
  final VoidCallback onTap;

  /// 글 칸의 줄 수.
  static const _lines = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = entry.media.firstOrNull;
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).walkMapPinPreviewOpen,
      child: GestureDetector(
        key: ValueKey('map-pin-preview-${entry.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: AppRadius.smAll,
          child: SizedBox.square(
            dimension: EntryPinLayer.previewSize,
            child: media != null
                ? EntryMediaView(media: media)
                : ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: entry.body.trim().isEmpty
                          ? Icon(
                              Icons.edit_note,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : Text(
                              entry.body.trim(),
                              maxLines: _lines,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
