import '../entity/alarm.dart';

/// 알람 정의 저장소. id 부여 · 정렬은 유스케이스가 한다.
abstract interface class AlarmRepository {
  Future<List<Alarm>> load();

  /// 전체를 통째로 바꿔 쓴다.
  Future<void> save(List<Alarm> alarms);
}
