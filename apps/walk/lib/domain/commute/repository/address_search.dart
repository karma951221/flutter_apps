import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_search.freezed.dart';

/// 주소 검색으로 찾은 장소 후보.
@freezed
class PlaceCandidate with _$PlaceCandidate {
  @override
  final double lat;

  @override
  final double lng;

  @override
  final String label;

  const PlaceCandidate({
    required this.lat,
    required this.lng,
    required this.label,
  });
}

/// 주소 · 장소 이름 → 좌표 후보.
abstract interface class AddressSearch {
  /// 빈 검색어 · 실패 · 시간 초과 · 결과 없음은 모두 `[]`.
  Future<List<PlaceCandidate>> search(String query);
}
