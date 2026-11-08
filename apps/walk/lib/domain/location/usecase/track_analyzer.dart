import '../entity/day_track.dart';
import '../entity/location_point.dart';
import '../entity/stay.dart';
import '../entity/track_segment.dart';
import '../geo/geo_math.dart';

/// 점들에서 이동선 구간과 머문 곳을 뽑는다.
class TrackAnalyzer {
  static const stayRadiusM = 100.0;
  static const stayMinDuration = Duration(minutes: 10);
  static const gap = Duration(minutes: 30);

  static const _oneMs = Duration(milliseconds: 1);

  /// [clipFrom] · [clipTo] 가 있으면 그 안으로 머문 곳을 자르고 구간 점도 거른다.
  DayTrack analyze(
    List<LocationPoint> points, {
    DateTime? clipFrom,
    DateTime? clipTo,
  }) {
    if (points.isEmpty) return const DayTrack(segments: [], stays: []);
    final sorted = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final groups = _split(sorted);
    final stays = <Stay>[];
    final segments = <TrackSegment>[];
    for (final g in groups) {
      for (final s in _stays(g)) {
        final clipped = _clip(s, clipFrom, clipTo);
        if (clipped != null) stays.add(clipped);
      }
      final pts = g.points
          .where(
            (p) =>
                (clipFrom == null || !p.recordedAt.isBefore(clipFrom)) &&
                (clipTo == null || !p.recordedAt.isAfter(clipTo)),
          )
          .toList();
      if (pts.isNotEmpty) {
        segments.add(TrackSegment(points: pts, mode: g.points.first.mode));
      }
    }
    return DayTrack(segments: segments, stays: stays);
  }

  List<_Group> _split(List<LocationPoint> sorted) {
    final groups = <_Group>[
      _Group([sorted.first]),
    ];
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final next = sorted[i];
      final current = groups.last;
      if (next.mode != prev.mode) {
        groups.add(_Group([next]));
        continue;
      }
      final far =
          haversineMeters(prev.lat, prev.lng, next.lat, next.lng) >
          stayRadiusM;
      final gapped = next.recordedAt.difference(prev.recordedAt) > gap;
      if (prev.stillStart && !far) {
        current.points.add(next); // 정지 중 공백 — 같은 자리에 머문 것
      } else if (prev.stillStart && far) {
        // 정지 감지로 비었던 시간은 머문 곳, 뒤 점 직전까지. 선은 잇지 않는다.
        if (gapped) current.endOverride = next.recordedAt.subtract(_oneMs);
        groups.add(_Group([next]));
      } else if (gapped) {
        groups.add(_Group([next]));
      } else {
        current.points.add(next);
      }
    }
    return groups;
  }

  /// 앞 점에서 반경 안에 머무는 최장 연속이 최소 시간 이상이면 머문 곳.
  List<Stay> _stays(_Group g) {
    final pts = g.points;
    final result = <Stay>[];
    var i = 0;
    while (i < pts.length) {
      var j = i + 1;
      while (j < pts.length &&
          haversineMeters(pts[i].lat, pts[i].lng, pts[j].lat, pts[j].lng) <=
              stayRadiusM) {
        j++;
      }
      final isLast = j == pts.length;
      final start = pts[i].recordedAt;
      final end = isLast && g.endOverride != null
          ? g.endOverride!
          : pts[j - 1].recordedAt;
      if (end.difference(start) >= stayMinDuration) {
        final run = pts.sublist(i, j);
        result.add(
          Stay(
            start: start,
            end: end,
            lat: run.fold(0.0, (s, p) => s + p.lat) / run.length,
            lng: run.fold(0.0, (s, p) => s + p.lng) / run.length,
            pointCount: run.length,
          ),
        );
        i = j;
      } else {
        i++;
      }
    }
    return result;
  }

  Stay? _clip(Stay s, DateTime? from, DateTime? to) {
    final start = from != null && s.start.isBefore(from) ? from : s.start;
    final end = to != null && s.end.isAfter(to) ? to : s.end;
    if (end.isBefore(start)) return null;
    return Stay(
      start: start,
      end: end,
      lat: s.lat,
      lng: s.lng,
      pointCount: s.pointCount,
    );
  }
}

class _Group {
  final List<LocationPoint> points;

  /// 정지 감지로 끝난 구간의 마지막 머문 곳이 끝나는 시각.
  DateTime? endOverride;

  _Group(this.points);
}
