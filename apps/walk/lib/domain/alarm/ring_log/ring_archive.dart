import '../entity/archived_ring.dart';

/// 울림 기록을 오래 보관하는 곳(네이티브 `RingLog` 는 200줄만 남는다).
abstract interface class RingArchive {
  /// 같은 `(at, packageId, kind)` 가 이미 있으면 건너뛴다. 처음 적힌 라벨이 남는다.
  Future<void> saveAll(List<ArchivedRing> rings);

  /// [from] 이상 [to] 이하를 오래된 것부터.
  Future<List<ArchivedRing>> read({required DateTime from, required DateTime to});
}
