/// 폰 인증 결과. [canceled] 는 실패로 치지 않는다(스펙 §7).
enum DeviceAuthResult {
  success,

  /// 인증을 통과하지 못했다 — 24시간 차단.
  failed,

  /// 사용자 · 시스템이 창을 닫았거나 시간이 지났다.
  canceled,

  /// 화면 잠금이 없거나 인증 창을 띄울 수 없다.
  unavailable,

  /// 폰이 너무 많은 실패로 인증을 잠갔다.
  lockedOut,
}

/// 폰 화면 잠금(기기 PIN · 생체)으로 본인 확인.
abstract interface class DeviceAuth {
  Future<bool> hasScreenLock();

  Future<DeviceAuthResult> authenticate(String reason);
}
