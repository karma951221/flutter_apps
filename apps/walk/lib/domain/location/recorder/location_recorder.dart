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

  /// inbox 의 오래된 점부터 최대 [limit] 개. 비우지는 않는다.
  Future<List<({int id, LocationPoint point})>> drain({int limit = 2000});

  /// [upToId] 이하 점을 inbox 에서 지운다.
  Future<void> ack(int upToId);
}
