import 'package:freezed_annotation/freezed_annotation.dart';

part 'place.freezed.dart';

enum PlaceKind { home, work }

/// 집 또는 회사 위치. 설정에 JSON 으로 저장한다.
@freezed
class Place with _$Place {
  @override
  final PlaceKind kind;

  @override
  final double lat;

  @override
  final double lng;

  @override
  final String label;

  const Place({
    required this.kind,
    required this.lat,
    required this.lng,
    required this.label,
  });

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'lat': lat,
        'lng': lng,
        'label': label,
      };

  /// 깨진 값이면 null.
  static Place? fromJson(Object? json) {
    if (json is! Map) return null;
    final kindName = json['kind'];
    final lat = json['lat'];
    final lng = json['lng'];
    final label = json['label'];
    if (kindName is! String || lat is! num || lng is! num || label is! String) {
      return null;
    }
    for (final kind in PlaceKind.values) {
      if (kind.name == kindName) {
        return Place(
          kind: kind,
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          label: label,
        );
      }
    }
    return null;
  }
}
