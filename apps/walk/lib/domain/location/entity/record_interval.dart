import 'record_mode.dart';

/// 위치 기록 주기 — 사용자가 고른다.
///
/// [normal] 은 평소(배터리 아낌): 몇 분 간격 · 50m · 묶음 전달 · 멈추면 정지 감지로 쉰다.
/// 나머지는 고정 주기([seconds]) 기록이다(네이티브 모드 `dense`, 정확도 우선 · 10m 넘게 움직일 때만).
/// 예전 "자세히 기록"은 [s5] 와 같다.
enum RecordInterval {
  normal(null),
  s5(5),
  s10(10),
  s30(30),
  m1(60);

  const RecordInterval(this.seconds);

  /// 고정 주기(초). 평소면 null.
  final int? seconds;

  /// 네이티브 기록 모드.
  RecordMode get mode => seconds == null ? RecordMode.normal : RecordMode.dense;

  /// 이 이하 고정 주기는 "자세히" — 지도에서 굵게 그리고 설명도 배터리를 많이 쓴다고 한다.
  static const detailedMaxSeconds = 30;

  /// 고정 주기 기록 중 고를 수 있는 가장 짧은 주기(초). 네이티브도 이보다 짧게 받지 않는다.
  static const minSeconds = 5;

  /// 상태 → 주기. 평소 모드면 [normal], 아니면 [seconds] 에 가장 가까운 고정 주기.
  static RecordInterval of(RecordMode mode, int seconds) {
    if (mode == RecordMode.normal) return normal;
    final fixed = values.where((v) => v.seconds != null);
    return fixed.reduce(
      (a, b) =>
          (a.seconds! - seconds).abs() <= (b.seconds! - seconds).abs() ? a : b,
    );
  }
}
