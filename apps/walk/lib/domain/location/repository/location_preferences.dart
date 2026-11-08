import '../entity/record_retention.dart';

/// 위치 기록 설정. 읽기는 동기, 저장된 값이 깨졌으면 기본값([RecordRetention.never]).
abstract interface class LocationPreferences {
  RecordRetention get retention;
  Future<void> setRetention(RecordRetention value);
}
