import 'dart:math' as math;

const _earthRadiusM = 6371000.0;

double _rad(double deg) => deg * math.pi / 180;

/// 두 좌표 사이 거리(미터, 대원 거리).
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(a)));
}

/// 위도 · 경도를 소수 3자리(약 100m)로 줄인 격자 키.
String gridKey(double lat, double lng) =>
    '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
