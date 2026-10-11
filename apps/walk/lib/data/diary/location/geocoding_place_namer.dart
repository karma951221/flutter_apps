import 'dart:async';
import 'dart:ui';

import 'package:geocoding/geocoding.dart';

import '../../../domain/diary/location/place_source.dart';

/// 장소 이름 조합: `[locality, subLocality, thoroughfare]` 중 비지 않은 앞의
/// 두 개를 공백으로 잇는다. Android 에서 어느 필드가 채워지는지는 기기 확인 전이라
/// 규칙을 여기 한 곳에 둔다(스펙 §11).
String? composePlaceName(Placemark placemark) {
  final parts = [
    for (final v in [
      placemark.locality,
      placemark.subLocality,
      placemark.thoroughfare,
    ])
      if (v != null && v.trim().isNotEmpty) v.trim(),
  ];
  return parts.isEmpty ? null : parts.take(2).join(' ');
}

typedef PlacemarkLookup =
    Future<List<Placemark>> Function(double lat, double lng, Locale locale);

/// `geocoding` 으로 이름을 얻는다. 생성자의 locale 은 버려지므로(스펙 §11) 호출마다
/// 넘기고, Android 13+ 에서 백엔드가 응답하지 않으면 Future 가 끝나지 않으므로
/// [timeout] 으로 끊는다. 예외 · 시간 초과는 null.
class GeocodingPlaceNamer implements PlaceNamer {
  GeocodingPlaceNamer({
    PlacemarkLookup? placemarks,
    Locale Function()? locale,
    this.timeout = const Duration(seconds: 8),
  }) : _placemarks = placemarks ?? _lookup,
       _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final PlacemarkLookup _placemarks;
  final Locale Function() _locale;
  final Duration timeout;

  static Future<List<Placemark>> _lookup(
    double lat,
    double lng,
    Locale locale,
  ) => Geocoding().placemarkFromCoordinates(lat, lng, locale: locale);

  @override
  Future<String?> nameFor(double lat, double lng) async {
    try {
      final found = await _placemarks(lat, lng, _locale()).timeout(timeout);
      for (final placemark in found) {
        final name = composePlaceName(placemark);
        if (name != null) return name;
      }
    } on Object {
      // 네트워크 없음 · 기기 미지원 · 시간 초과: 좌표만 둔다.
    }
    return null;
  }
}
