import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/settings/repository/settings_repository.dart';
import 'package:walk/presentation/settings/cubit/theme_cubit.dart';

class _MockRepository extends Mock implements SettingsRepository {}

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const AppSettings()));
  setUp(() {
    repository = _MockRepository();
    when(() => repository.load())
        .thenReturn(const AppSettings(themeMode: AppThemeMode.dark));
    when(() => repository.save(any())).thenAnswer((_) async {});
  });

  test('처음 값은 저장된 테마(동기)', () {
    expect(ThemeCubit(repository).state, AppThemeMode.dark);
  });

  blocTest<ThemeCubit, AppThemeMode>(
    'select 는 즉시 반영하고 저장한다',
    build: () => ThemeCubit(repository),
    act: (cubit) => cubit.select(AppThemeMode.light),
    expect: () => [AppThemeMode.light],
    verify: (_) => verify(
      () => repository.save(const AppSettings(themeMode: AppThemeMode.light)),
    ).called(1),
  );

  blocTest<ThemeCubit, AppThemeMode>(
    '같은 값이면 아무것도 하지 않는다',
    build: () => ThemeCubit(repository),
    act: (cubit) => cubit.select(AppThemeMode.dark),
    expect: () => <AppThemeMode>[],
    verify: (_) => verifyNever(() => repository.save(any())),
  );
}
