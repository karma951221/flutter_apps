import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCommuteUseCase extends Mock implements CommuteUseCase {}

const _home = Station(
  id: '0750',
  name: '장승배기',
  lines: ['7'],
  location: GeoPoint(lat: 37.5048, lng: 126.9392),
);

const _work = Station(
  id: '0222',
  name: '강남',
  lines: ['2', '신분당'],
  location: GeoPoint(lat: 37.4979, lng: 127.0276),
);

void main() {
  late _MockCommuteUseCase useCase;

  setUpAll(() => registerFallbackValue(const CommuteSettings()));
  setUp(() => useCase = _MockCommuteUseCase());

  blocTest<CommuteSettingsCubit, CommuteSettingsState>(
    '설정을 읽어 loaded로 간다',
    build: () {
      when(
        () => useCase.getSettings(),
      ).thenAnswer((_) async => const Ok(CommuteSettings(home: _home)));
      return CommuteSettingsCubit(useCase);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      CommuteSettingsState.loading(),
      CommuteSettingsState.loaded(CommuteSettings(home: _home)),
    ],
  );

  blocTest<CommuteSettingsCubit, CommuteSettingsState>(
    '집 역을 선택하면 기존 회사 역을 보존해 저장한다',
    build: () {
      when(
        () => useCase.saveSettings(any()),
      ).thenAnswer((_) async => const Ok(null));
      return CommuteSettingsCubit(useCase);
    },
    seed: () => const CommuteSettingsState.loaded(CommuteSettings(work: _work)),
    act: (cubit) => cubit.setHome(_home),
    expect: () => const [
      CommuteSettingsState.loaded(CommuteSettings(home: _home, work: _work)),
    ],
    verify: (_) => verify(
      () =>
          useCase.saveSettings(const CommuteSettings(home: _home, work: _work)),
    ).called(1),
  );

  blocTest<CommuteSettingsCubit, CommuteSettingsState>(
    '저장이 실패하면 failure로 간다',
    build: () {
      when(
        () => useCase.saveSettings(any()),
      ).thenAnswer((_) async => const Err(Failure.unknown()));
      return CommuteSettingsCubit(useCase);
    },
    seed: () => const CommuteSettingsState.loaded(CommuteSettings()),
    act: (cubit) => cubit.setWork(_work),
    expect: () => const [CommuteSettingsState.failure(Failure.unknown())],
  );
}
