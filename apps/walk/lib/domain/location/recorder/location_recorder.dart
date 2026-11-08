import '../entity/location_point.dart';
import '../entity/record_mode.dart';
import 'recorder_status.dart';

/// 네이티브 위치 기록 서비스. 점은 네이티브 inbox 에 쌓이고 [drain] 으로 가져와
/// 저장한 뒤 [ack] 로 비운다.
abstract interface class LocationRecorder {
  Future<RecorderStatus> status();
  Future<void> start(RecordMode mode);
  Future<void> stop();
  Future<void> setMode(RecordMode mode);

  /// 시스템 배터리 최적화 화면을 연다. 앱은 아무것도 바꾸지 않는다.
  Future<void> openBatterySettings();

  /// inbox 의 오래된 점부터 최대 [limit] 개. 비우지는 않는다.
  Future<List<({int id, LocationPoint point})>> drain({int limit = 2000});

  /// [upToId] 이하 점을 inbox 에서 지운다.
  Future<void> ack(int upToId);

  /// inbox 를 모두 비운다(아직 수거하지 않은 점까지). 기록 모두 지우기가 저장소보다 먼저 부른다 —
  /// 남겨 두면 다음 수거가 지운 기록을 다시 들여온다.
  Future<void> clearInbox();
}
