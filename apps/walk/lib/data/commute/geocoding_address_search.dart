import 'dart:async';
import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:injectable/injectable.dart';
import 'package:walk/domain/commute/repository/address_search.dart';
import 'package:walk/domain/diary/location/place_lookup.dart';
import 'package:walk/domain/diary/location/place_source.dart';

typedef LocationsLookup =
    Future<List<Location>> Function(String query, Locale locale);

/// `geocoding` 으로 주소를 좌표로 바꾸고, 좌표마다 [PlaceNamer] 로 이름을 붙인다.
/// `GeocodingPlaceNamer` 처럼 locale 은 호출마다 넘기고, 응답이 없을 수 있어
/// [timeout] 으로 끊는다.
@LazySingleton(as: AddressSearch)
class GeocodingAddressSearch implements AddressSearch {
  GeocodingAddressSearch(
    this._namer, {
    @ignoreParam LocationsLookup? locations,
    @ignoreParam Locale Function()? locale,
    @ignoreParam this.timeout = const Duration(seconds: 8),
  }) : _locations = locations ?? _lookup,
       _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final PlaceNamer _namer;
  final LocationsLookup _locations;
  final Locale Function() _locale;
  final Duration timeout;

  static const _maxCandidates = 5;

  static Future<List<Location>> _lookup(String query, Locale locale) =>
      Geocoding().locationFromAddress(query, locale: locale);

  @override
  Future<List<PlaceCandidate>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final List<Location> found;
    try {
      found = await _locations(trimmed, _locale()).timeout(timeout);
    } on Object {
      // 결과 없음(플랫폼 예외) · 네트워크 없음 · 시간 초과.
      return const [];
    }
    return Future.wait([
      for (final location in found.take(_maxCandidates))
        _candidate(location, trimmed),
    ]);
  }

  Future<PlaceCandidate> _candidate(Location location, String query) async {
    final lookup = await _namer.nameFor(location.latitude, location.longitude);
    return PlaceCandidate(
      lat: location.latitude,
      lng: location.longitude,
      label: switch (lookup) {
        PlaceNamed(:final name) => name,
        PlaceNoName() || PlaceOffline() => query,
      },
    );
  }
}
