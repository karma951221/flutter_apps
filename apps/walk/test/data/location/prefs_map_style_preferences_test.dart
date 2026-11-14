import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/location/prefs_map_style_preferences.dart';
import 'package:walk/domain/location/entity/map_style.dart';

Future<PrefsMapStylePreferences> _prefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsMapStylePreferences(await SharedPreferences.getInstance());
}

void main() {
  test('저장한 적이 없으면 단순 지도', () async {
    expect((await _prefs()).style, MapStyle.simple);
  });

  test('저장한 값을 새 인스턴스에서 다시 읽는다', () async {
    await (await _prefs()).setStyle(MapStyle.dark);

    final reader = PrefsMapStylePreferences(
      await SharedPreferences.getInstance(),
    );
    expect(reader.style, MapStyle.dark);
  });

  test('타입이 다르거나 모르는 이름이면 기본값', () async {
    expect(
      (await _prefs({PrefsMapStylePreferences.styleKey: 3})).style,
      MapStyle.simple,
    );
    expect(
      (await _prefs({PrefsMapStylePreferences.styleKey: 'hybrid'})).style,
      MapStyle.simple,
    );
    // 없앤 모양(글자 없이)을 저장해 둔 사람도 기본값.
    expect(
      (await _prefs({PrefsMapStylePreferences.styleKey: 'plain'})).style,
      MapStyle.simple,
    );
  });
}
