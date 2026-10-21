import '../../../domain/diary/entity/diary_entry.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/entity/story.dart';

/// 뷰어의 조각 하나. [media] 가 null 이면 미디어 없는 글 조각이다.
class ViewerSlide {
  const ViewerSlide({required this.entry, this.media});

  final DiaryEntry entry;
  final EntryMedia? media;
}

/// 스토리의 하루. [date] 는 로컬 자정이다.
class ViewerDay {
  const ViewerDay({required this.date, required this.slides});

  final DateTime date;
  final List<ViewerSlide> slides;
}

/// 뷰어가 가로로 넘기는 한 묶음. 모아보기(태그 · 장소)는 [story] 가 null 이다.
class ViewerGroup {
  const ViewerGroup({
    required this.id,
    required this.title,
    this.story,
    required this.days,
  });

  final String id;
  final String title;
  final Story? story;
  final List<ViewerDay> days;
}

/// 뷰어 안의 위치(그룹 · 날 · 조각 인덱스).
class ViewerPos {
  const ViewerPos(this.group, this.day, this.slide);

  final int group;
  final int day;
  final int slide;

  @override
  bool operator ==(Object other) =>
      other is ViewerPos &&
      other.group == group &&
      other.day == day &&
      other.slide == slide;

  @override
  int get hashCode => Object.hash(group, day, slide);

  @override
  String toString() => 'ViewerPos($group, $day, $slide)';
}

/// 휴지통 기록을 빼고 `occurredAt` 오름차순 · 로컬 날짜별로 묶는다.
ViewerGroup buildViewerGroup({
  required String id,
  required String title,
  Story? story,
  required List<DiaryEntry> entries,
}) {
  final live = entries.where((e) => !e.isTrashed).toList()
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  final byDay = <DateTime, List<ViewerSlide>>{};
  for (final e in live) {
    final at = e.occurredAt;
    final key = DateTime(at.year, at.month, at.day);
    final slides = byDay.putIfAbsent(key, () => []);
    if (e.media.isEmpty) {
      slides.add(ViewerSlide(entry: e));
    } else {
      slides.addAll(e.media.map((m) => ViewerSlide(entry: e, media: m)));
    }
  }
  return ViewerGroup(
    id: id,
    title: title,
    story: story,
    days: [
      for (final k in byDay.keys.toList()..sort())
        ViewerDay(date: k, slides: byDay[k]!),
    ],
  );
}

/// 그룹 [group] 의 시작 위치. 날이 없으면 null.
ViewerPos? startPos(
  List<ViewerGroup> groups,
  int group, {
  String? entryId,
  bool fromStart = false,
}) {
  if (group < 0 || group >= groups.length) return null;
  final g = groups[group];
  if (g.days.isEmpty) return null;
  if (entryId != null) {
    for (var d = 0; d < g.days.length; d++) {
      final s = g.days[d].slides.indexWhere((s) => s.entry.id == entryId);
      if (s >= 0) return ViewerPos(group, d, s);
    }
  }
  final story = g.story;
  final last = !fromStart && (story == null || story.isOpen);
  return ViewerPos(group, last ? g.days.length - 1 : 0, 0);
}

ViewerPos _lastOf(List<ViewerGroup> g, int group) {
  final days = g[group].days;
  return ViewerPos(group, days.length - 1, days.last.slides.length - 1);
}

/// 다음 조각 → 다음 날 → 다음 그룹(빈 그룹 건너뜀). 끝이면 null.
ViewerPos? nextPos(List<ViewerGroup> g, ViewerPos p) {
  final days = g[p.group].days;
  if (p.slide + 1 < days[p.day].slides.length) {
    return ViewerPos(p.group, p.day, p.slide + 1);
  }
  if (p.day + 1 < days.length) return ViewerPos(p.group, p.day + 1, 0);
  for (var i = p.group + 1; i < g.length; i++) {
    if (g[i].days.isNotEmpty) return ViewerPos(i, 0, 0);
  }
  return null;
}

/// 이전 조각 → 전날 마지막 조각 → 이전 그룹 마지막. 맨 처음이면 같은 위치.
ViewerPos prevPos(List<ViewerGroup> g, ViewerPos p) {
  if (p.slide > 0) return ViewerPos(p.group, p.day, p.slide - 1);
  if (p.day > 0) {
    final slides = g[p.group].days[p.day - 1].slides;
    return ViewerPos(p.group, p.day - 1, slides.length - 1);
  }
  for (var i = p.group - 1; i >= 0; i--) {
    if (g[i].days.isNotEmpty) return _lastOf(g, i);
  }
  return p;
}

/// 가로 스와이프: [delta] 방향으로 날이 있는 가장 가까운 그룹의 시작 위치.
/// 갈 곳이 없으면 null.
ViewerPos? groupStep(List<ViewerGroup> g, ViewerPos p, int delta) {
  if (delta == 0) return null;
  final step = delta.sign;
  var i = p.group + step * delta.abs();
  // delta 가 1 이 아니어도 그 거리 이후 첫 비어 있지 않은 그룹을 찾는다.
  for (; i >= 0 && i < g.length; i += step) {
    final pos = startPos(g, i);
    if (pos != null) return pos;
  }
  return null;
}

/// 스토리 시작일 기준 며칠째인지(1부터). 기본 스토리 · 모아보기는 null.
int? dayNumber(ViewerGroup g, ViewerDay d) {
  final s = g.story;
  if (s == null || s.isDefault) return null;
  final start = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
  // 일광절약 하루 길이 변동을 피해 UTC 로 날 수를 센다.
  final a = DateTime.utc(start.year, start.month, start.day);
  final b = DateTime.utc(d.date.year, d.date.month, d.date.day);
  return b.difference(a).inDays + 1;
}
