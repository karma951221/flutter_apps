import '../entity/alarm_sound.dart';

/// 기기 알람음 목록의 한 줄. [uri] 는 `content://…`.
typedef DeviceRingtone = ({String title, String uri});

/// 기기 알람음을 읽고, 미리 듣고, 앱 저장소로 복사한다. 실패는 [AlarmSoundException].
abstract interface class AlarmSoundSource {
  /// 기기 알람음 목록(RingtoneManager TYPE_ALARM).
  Future<List<DeviceRingtone>> deviceRingtones();

  /// 미리 듣기. 이미 재생 중이면 바꿔 튼다. 알람 볼륨(USAGE_ALARM)으로 반복 재생.
  /// [uri] 를 주면(아직 복사 전인 기기 알람음) [sound] 대신 그것을 튼다.
  Future<void> preview(AlarmSound sound, {String? uri});

  Future<void> stopPreview();

  /// 기기 알람음을 앱 저장소에 복사하고 [AlarmSound.device] 를 돌려준다.
  Future<AlarmSound> import(DeviceRingtone ringtone);
}

/// 알람음 소스가 실패했다(목록 읽기 · 재생 · 복사).
class AlarmSoundException implements Exception {
  const AlarmSoundException(this.message);

  final String message;

  @override
  String toString() => 'AlarmSoundException: $message';
}
