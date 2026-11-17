import 'package:freezed_annotation/freezed_annotation.dart';

part 'station_hit.freezed.dart';

enum StationKind { subway, bus }

/// 역 · 정류장 검색 결과 한 건.
@freezed
class StationHit with _$StationHit {
  @override
  final String name;

  @override
  final StationKind kind;

  @override
  final double lat;

  @override
  final double lng;

  @override
  final String detail;

  const StationHit({
    required this.name,
    required this.kind,
    required this.lat,
    required this.lng,
    required this.detail,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'kind': kind.name,
    'lat': lat,
    'lng': lng,
    'detail': detail,
  };

  /// 깨진 값이면 null.
  static StationHit? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final kindName = json['kind'];
    final lat = json['lat'];
    final lng = json['lng'];
    final detail = json['detail'];
    if (name is! String ||
        kindName is! String ||
        lat is! num ||
        lng is! num ||
        detail is! String) {
      return null;
    }
    for (final kind in StationKind.values) {
      if (kind.name == kindName) {
        return StationHit(
          name: name,
          kind: kind,
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          detail: detail,
        );
      }
    }
    return null;
  }
}
