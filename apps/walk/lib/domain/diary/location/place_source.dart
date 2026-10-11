import '../entity/entry_location.dart';

/// 좌표 → 장소 이름. 실패 · 네트워크 없음 · 시간 초과는 모두 null.
abstract interface class PlaceNamer {
  Future<String?> nameFor(double lat, double lng);
}

/// 지금 위치와 그 이름.
abstract interface class PlaceSource {
  /// 위치 서비스 꺼짐 · 권한 거부 · 시간 초과 → null(오류 아님).
  /// 좌표는 있고 이름이 없으면 `placeName` 이 null 이다.
  Future<EntryLocation?> current();

  /// 오프라인으로 저장한 기록의 이름을 나중에 채울 때 쓴다.
  Future<String?> nameFor(double lat, double lng);
}
