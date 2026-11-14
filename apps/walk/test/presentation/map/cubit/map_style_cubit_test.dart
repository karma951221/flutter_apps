import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/location/entity/map_style.dart';
import 'package:walk/presentation/map/cubit/map_style_cubit.dart';

import '../../../support/fake_map_style_preferences.dart';

void main() {
  test('처음 값은 저장된 모양', () async {
    final cubit = MapStyleCubit(FakeMapStylePreferences(MapStyle.dark));
    addTearDown(cubit.close);

    expect(cubit.state, MapStyle.dark);
  });

  test('select 는 바로 반영하고 저장한다', () async {
    final prefs = FakeMapStylePreferences();
    final cubit = MapStyleCubit(prefs);
    addTearDown(cubit.close);

    await cubit.select(MapStyle.dark);

    expect(cubit.state, MapStyle.dark);
    expect(prefs.style, MapStyle.dark);
  });

  test('같은 모양이면 아무것도 하지 않는다', () async {
    final prefs = _CountingPrefs();
    final cubit = MapStyleCubit(prefs);
    addTearDown(cubit.close);

    await cubit.select(MapStyle.simple);

    expect(prefs.saves, 0);
  });
}

class _CountingPrefs extends FakeMapStylePreferences {
  int saves = 0;

  @override
  Future<void> setStyle(MapStyle value) async {
    saves++;
    await super.setStyle(value);
  }
}
