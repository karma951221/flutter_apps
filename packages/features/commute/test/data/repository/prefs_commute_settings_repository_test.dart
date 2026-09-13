import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStationRepository extends Mock implements StationRepository {}

const _home = Station(
  id: '0739',
  name: '장승배기',
  lines: ['7'],
  location: GeoPoint(lat: 37.5048, lng: 126.9391),
);
const _work = Station(
  id: '0222',
  name: '강남',
  lines: ['2'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);

void main() {
  late SharedPreferences preferences;
  late _MockStationRepository stationRepository;
  late PrefsCommuteSettingsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    stationRepository = _MockStationRepository();
    repository = PrefsCommuteSettingsRepository(preferences, stationRepository);
  });

  test('역 id만 저장하고 StationRepository로 복원한다', () async {
    when(
      () => stationRepository.findById(_home.id),
    ).thenAnswer((_) async => const Ok(_home));
    when(
      () => stationRepository.findById(_work.id),
    ).thenAnswer((_) async => const Ok(_work));

    final saveResult = await repository.save(
      const CommuteSettings(home: _home, work: _work),
    );
    final loadResult = await repository.load();

    expect(saveResult, isA<Ok<void>>());
    expect(
      preferences.getString(PrefsCommuteSettingsRepository.homeStationKey),
      _home.id,
    );
    expect(
      (loadResult as Ok<CommuteSettings>).value,
      const CommuteSettings(home: _home, work: _work),
    );
  });

  test('저장된 키가 없으면 빈 설정을 반환한다', () async {
    final result = await repository.load();

    expect((result as Ok<CommuteSettings>).value, const CommuteSettings());
    verifyNever(() => stationRepository.findById(any()));
  });

  test('역 목록에 없는 저장 id는 null로 복원한다', () async {
    await preferences.setString(
      PrefsCommuteSettingsRepository.homeStationKey,
      'missing',
    );
    when(
      () => stationRepository.findById('missing'),
    ).thenAnswer((_) async => const Ok(null));

    final result = await repository.load();

    expect((result as Ok<CommuteSettings>).value.home, isNull);
  });
}
