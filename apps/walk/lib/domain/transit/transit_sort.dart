import 'entity/transit_path.dart';

/// 총 소요 시간 → 환승 → 도보 시간 순으로 오름차순 정렬한 새 목록.
List<TransitPath> sortTransitPaths(Iterable<TransitPath> paths) {
  final sorted = paths.toList();
  sorted.sort((a, b) {
    final byTotal = a.totalMinutes.compareTo(b.totalMinutes);
    if (byTotal != 0) return byTotal;
    final byTransfer = a.transferCount.compareTo(b.transferCount);
    if (byTransfer != 0) return byTransfer;
    return a.walkMinutes.compareTo(b.walkMinutes);
  });
  return sorted;
}
