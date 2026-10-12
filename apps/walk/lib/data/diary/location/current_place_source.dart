import 'dart:async';

import 'package:location/location.dart';

import '../../../domain/diary/entity/entry_location.dart';
import '../../../domain/diary/location/place_lookup.dart';
import '../../../domain/diary/location/place_source.dart';

/// 지금 위치를 읽고 [PlaceNamer] 로 이름을 붙인다. 권한은 [LocationAccess] 가
/// 세션당 한 번만 묻는다.
class CurrentPlaceSource implements PlaceSource {
  CurrentPlaceSource(
    this._access,
    this._gateway,
    this._namer, {
    this.timeout = const Duration(seconds: 10),
  });

  final LocationAccess _access;
  final LocationGateway _gateway;
  final PlaceNamer _namer;
  final Duration timeout;

  @override
  Future<EntryLocation?> current() async {
    try {
      if (await _access.ensure() != LocationAccessStatus.granted) return null;
      final position = await _gateway
          .getCurrentPosition(accuracy: LocationAccuracy.high, timeout: timeout)
          .timeout(timeout);
      final lookup = await _namer.nameFor(
        position.latitude,
        position.longitude,
      );
      return EntryLocation(
        placeName: switch (lookup) {
          PlaceNamed(:final name) => name,
          PlaceNoName() || PlaceOffline() => null,
        },
        lat: position.latitude,
        lng: position.longitude,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<PlaceLookup> nameFor(double lat, double lng) =>
      _namer.nameFor(lat, lng);
}
