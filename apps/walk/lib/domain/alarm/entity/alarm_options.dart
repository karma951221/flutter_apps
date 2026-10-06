/// 알람별 울림 설정의 선택지와 기본값(웨이브 3 스펙 §2 · §3.1). 저장된 값이 선택지 밖이면
/// `Alarm.fromJson` 이 기본값으로 읽는다.
abstract final class AlarmOptions {
  /// 볼륨(%). 0% 는 무음이 되므로 10 부터.
  static const volumePercents = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
  static const defaultVolumePercent = 80;

  /// 점점 커지기(초). 0 은 끔.
  static const fadeSeconds = [0, 30, 60];
  static const defaultFadeSeconds = 0;

  /// 스누즈 간격(분).
  static const snoozeMinutes = [5, 10, 15];
  static const defaultSnoozeMinutes = 5;

  /// 스누즈 최대 횟수. null 은 무제한(기본).
  static const snoozeLimits = <int?>[null, 3];

  /// 자동 멈춤(분). null 은 안 함(기본).
  static const autoStopMinutes = <int?>[null, 5, 10, 15];
}
