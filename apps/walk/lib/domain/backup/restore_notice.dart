/// 복원(또는 되돌리기)이 끝난 뒤 결과 화면에 띄울 안내. 영역의 `afterRestore` 가 돌려준다.
enum RestoreNotice {
  /// 백업에 사본이 없는 알람음을 기본 알람음으로 바꿨다.
  alarmSoundFallback,

  /// 알람이 제때 울리는 데 필요한 권한(알림 · 정확한 알람)이 꺼져 있다.
  alarmPermissionNeeded,

  /// 위치 기록 데이터만 복원했다 — 기록 서비스는 꺼진 채다.
  locationRecordingOff,

  /// 물어보기 API 키는 백업에 없다 — 다시 넣어야 한다.
  apiKeyNeeded,
}
