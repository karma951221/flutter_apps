import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/domain/commute/entity/place.dart';
import 'package:walk/domain/commute/repository/place_repository.dart';

@LazySingleton(as: PlaceRepository)
class PrefsPlaceRepository implements PlaceRepository {
  PrefsPlaceRepository(this._prefs);

  final SharedPreferences _prefs;

  static const homeKey = 'commute.place.home';
  static const workKey = 'commute.place.work';

  static String _key(PlaceKind kind) => switch (kind) {
    PlaceKind.home => homeKey,
    PlaceKind.work => workKey,
  };

  @override
  Place? load(PlaceKind kind) {
    // getString 은 문자열이 아닌 값에서 던진다 — get 으로 읽는다.
    final raw = _prefs.get(_key(kind));
    if (raw is! String) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    final place = Place.fromJson(json);
    return place?.kind == kind ? place : null;
  }

  @override
  Future<void> save(Place place) =>
      _prefs.setString(_key(place.kind), jsonEncode(place.toJson()));
}
