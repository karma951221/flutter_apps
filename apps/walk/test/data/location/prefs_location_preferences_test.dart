import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/location/prefs_location_preferences.dart';
import 'package:walk/domain/location/entity/record_retention.dart';

Future<PrefsLocationPreferences> _prefs([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return PrefsLocationPreferences(await SharedPreferences.getInstance());
}

void main() {
  test('저장한 적이 없으면 지우지 않음', () async {
    final prefs = await _prefs();

    expect(prefs.retention, RecordRetention.never);
  });

  test('저장한 값을 새 인스턴스에서 다시 읽는다', () async {
    final writer = await _prefs();

    await writer.setRetention(RecordRetention.oneYear);

    final reader = PrefsLocationPreferences(
      await SharedPreferences.getInstance(),
    );
    expect(reader.retention, RecordRetention.oneYear);
  });

  test('타입이 다르거나 모르는 이름이면 기본값', () async {
    final wrongType = await _prefs({PrefsLocationPreferences.retentionKey: 3});
    expect(wrongType.retention, RecordRetention.never);

    final unknown = await _prefs({
      PrefsLocationPreferences.retentionKey: 'week',
    });
    expect(unknown.retention, RecordRetention.never);
  });

  test('cutoff', () {
    final now = DateTime(2026, 11, 8);

    expect(RecordRetention.threeMonths.cutoff(now), DateTime(2026, 8, 8));
    expect(RecordRetention.oneYear.cutoff(now), DateTime(2025, 11, 8));
    expect(RecordRetention.never.cutoff(now), isNull);
  });
}
