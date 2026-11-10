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

  /// 정지 감지 점 없이 같은 자리 공백을 머문 것으로 잇는 최대 길이. 더 길면 기록이 꺼져 있던
  /// 것일 수 있어 끊는다(정지 감지 점 뒤는 제한 없음).
  static const sameSpotMaxGap = Duration(hours: 12);

  static const _oneMs = Duration(milliseconds: 1);

  /// [clipFrom] · [clipTo] 가 있으면 그 안으로 머문 곳을 자르고 구간 점도 거른다.
  /// [openEnd](기록 중일 때의 지금)가 마지막 점보다 뒤면 마지막 머문 곳이 아직 이어지는 것으로 보고
  /// [openEnd] 에 닫는다 — 마지막 점이 정지 감지 점이면 언제나, 아니면 그 점이 창 안이고
  /// [sameSpotMaxGap] 안일 때만. 창 밖은 자르기가 다듬는다.
  DayTrack analyze(
    List<LocationPoint> points, {
    DateTime? clipFrom,
    DateTime? clipTo,
    DateTime? openEnd,
  }) {
    if (points.isEmpty) return const DayTrack(segments: [], stays: []);
    final sorted = [...points]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final groups = _split(sorted);
    final last = sorted.last.recordedAt;
    if (openEnd != null && openEnd.isAfter(last)) {
      final inWindow =
          (clipFrom == null || !last.isBefore(clipFrom)) &&
          (clipTo == null || !last.isAfter(clipTo));
      if (sorted.last.stillStart ||
          (inWindow && openEnd.difference(last) <= sameSpotMaxGap)) {
        groups.last.endOverride = openEnd;
      }
    }
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
    // 정지 감지 점으로 시작한 머묾의 기준 점. 심장박동(이어진 정지 감지 점)도 이 점과 잰다 —
    // 네이티브가 정지 점과 재는 것과 같게.
    var anchor = sorted.first.stillStart ? sorted.first : null;
    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final next = sorted[i];
      final current = groups.last;
      final groupsBefore = groups.length;
      final pause = next.recordedAt.difference(prev.recordedAt);
      if (prev.stillStart) {
        final ref = anchor ?? prev;
        final far =
            haversineMeters(ref.lat, ref.lng, next.lat, next.lng) > stayRadiusM;
        if (!far && next.mode == prev.mode) {
          current.points.add(next); // 정지 중 공백 — 같은 자리에 머문 것
        } else {
          // 정지 감지 뒤엔 위치 요청이 멈춰 있으니 빈 시간은 공백 길이와 무관하게
          // 머문 곳, 뒤 점 직전까지. 멀리 갔거나 모드가 바뀌었으면 선은 잇지 않는다.
          current.endOverride = next.recordedAt.subtract(_oneMs);
          groups.add(_Group([next]));
        }
      } else {
        final far =
            haversineMeters(prev.lat, prev.lng, next.lat, next.lng) >
            stayRadiusM;
        if (next.mode != prev.mode) {
          // 같은 자리에서 모드만 바뀌었으면 머문 곳을 그 점 직전까지로 닫는다.
          if (!far && pause <= sameSpotMaxGap) {
            current.endOverride = next.recordedAt.subtract(_oneMs);
          }
          groups.add(_Group([next]));
        } else if (far ? pause > gap : pause > sameSpotMaxGap) {
          groups.add(_Group([next]));
        } else {
          // 긴 공백이어도 같은 자리면(12시간까지) 머문 것 — 정지 감지가 꺼져 있으면(활동 인식
          // 거부 · 정밀 모드) 최소 이동 거리 때문에 가만히 있는 동안 점이 안 남는다.
          current.points.add(next);
        }
      }
      if (!next.stillStart) {
        anchor = null;
      } else if (anchor == null || groups.length != groupsBefore) {
        anchor = next;
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
