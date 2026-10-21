import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/domain/commute/entity/commute_direction.dart';
import 'package:walk/domain/commute/repository/route_preference_repository.dart';

@LazySingleton(as: RoutePreferenceRepository)
class PrefsRoutePreferenceRepository implements RoutePreferenceRepository {
  PrefsRoutePreferenceRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _key(CommuteDirection d) => 'commute.route.${d.name}';

  @override
  String? load(CommuteDirection d) {
    final value = _prefs.get(_key(d));
    return value is String ? value : null;
  }

  @override
  Future<void> save(CommuteDirection d, String signature) =>
      _prefs.setString(_key(d), signature);
}
