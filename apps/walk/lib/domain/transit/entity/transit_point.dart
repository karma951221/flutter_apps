import 'package:freezed_annotation/freezed_annotation.dart';

part 'transit_point.freezed.dart';

enum TransitPointSource {
  currentLocation,
  home,
  work,
  frequent,
  recent,
  station,
  address,
}

/// 길찾기의 출발 · 도착 지점.
@freezed
class TransitPoint with _$TransitPoint {
  @override
  final double lat;

  @override
  final double lng;

  @override
  final String label;

  @override
  final TransitPointSource source;

  const TransitPoint({
    required this.lat,
    required this.lng,
    required this.label,
    required this.source,
  });

  /// 경로 캐시 키. 소수 넷째 자리까지 반올림한 좌표.
  String get cacheKey => '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  Map<String, Object?> toJson() => {
    'lat': lat,
    'lng': lng,
    'label': label,
    'source': source.name,
  };

  /// 깨진 값이면 null.
  static TransitPoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    final label = json['label'];
    final sourceName = json['source'];
    if (lat is! num ||
        lng is! num ||
        label is! String ||
        sourceName is! String) {
      return null;
    }
    for (final source in TransitPointSource.values) {
      if (source.name == sourceName) {
        return TransitPoint(
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          label: label,
          source: source,
        );
      }
    }
    return null;
  }
}
