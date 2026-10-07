import '../entity/ring_log_entry.dart';

/// 울림 기록 저장소(포크 네이티브 `RingLog` — 앱이 꺼져 있어도 울림 · 끔 · 스누즈가 남는다).
abstract interface class RingLogSource {
  /// [since] 이후(포함) 기록. 오래된 것부터.
  Future<List<RingLogEntry>> read({required DateTime since});

  /// 기록 한 줄을 덧붙인다(건너뛰기).
  Future<void> append(RingLogEntry entry);
}
