import '../entity/frequent_place.dart';
import '../entity/stay.dart';
import '../geo/geo_math.dart';

/// 머문 곳을 격자로 묶어 방문 횟수(같으면 머문 시간) 순 상위 [limit] 곳.
List<FrequentPlace> frequentPlaces(List<Stay> stays, {int limit = 10}) {
  final groups = <String, List<Stay>>{};
  for (final s in stays) {
    groups.putIfAbsent(gridKey(s.lat, s.lng), () => []).add(s);
  }
  final places = [
    for (final e in groups.entries)
      FrequentPlace(
        gridKey: e.key,
        lat: e.value.fold(0.0, (a, s) => a + s.lat) / e.value.length,
        lng: e.value.fold(0.0, (a, s) => a + s.lng) / e.value.length,
        visits: e.value.length,
        total: e.value.fold(Duration.zero, (a, s) => a + s.duration),
      ),
  ];
  places.sort((a, b) {
    final byVisits = b.visits.compareTo(a.visits);
    return byVisits != 0 ? byVisits : b.total.compareTo(a.total);
  });
  return places.take(limit).toList();
}
