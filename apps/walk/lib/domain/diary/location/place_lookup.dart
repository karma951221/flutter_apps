import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_lookup.freezed.dart';

/// 좌표 → 장소 이름 찾기의 결과.
///
/// [PlaceOffline] 은 지금은 물어볼 수 없다(네트워크 없음 · 시간 초과 · 기기 미지원) —
/// 나중에 다시 묻는다. [PlaceNoName] 은 물어봤지만 이 좌표에 붙일 이름이 없다(바다 한가운데 등) —
/// 다른 좌표는 이름이 있을 수 있다.
@freezed
sealed class PlaceLookup with _$PlaceLookup {
  const factory PlaceLookup.named(String name) = PlaceNamed;
  const factory PlaceLookup.noName() = PlaceNoName;
  const factory PlaceLookup.offline() = PlaceOffline;
}
