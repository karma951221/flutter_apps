import 'package:daylog/features/theme/domain/entity/app_theme_mode.dart';
import 'package:daylog/features/theme/domain/usecase/theme_use_case.dart';
import 'package:daylog/features/theme/presentation/cubit/theme_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockThemeUseCase extends Mock implements ThemeUseCase {}

void main() {
  late _MockThemeUseCase useCase;

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    useCase = _MockThemeUseCase();
    when(() => useCase.saveThemeMode(any())).thenAnswer((_) async {});
  });

  test('초기 상태는 저장된 값이다', () {
    when(useCase.loadThemeMode).thenReturn(AppThemeMode.dark);

    final cubit = ThemeCubit(useCase);

    expect(cubit.state, AppThemeMode.dark);
    addTearDown(cubit.close);
  });

  test('저장된 값이 없으면 시스템으로 시작한다', () {
    when(useCase.loadThemeMode).thenReturn(AppThemeMode.system);

    final cubit = ThemeCubit(useCase);

    expect(cubit.state, AppThemeMode.system);
    addTearDown(cubit.close);
  });

  test('setMode 는 상태를 바꾸고 저장한다', () async {
    when(useCase.loadThemeMode).thenReturn(AppThemeMode.system);
    final cubit = ThemeCubit(useCase);
    addTearDown(cubit.close);

    final emitted = <AppThemeMode>[];
    final subscription = cubit.stream.listen(emitted.add);

    await cubit.setMode(AppThemeMode.dark);

    expect(cubit.state, AppThemeMode.dark);
    expect(emitted, [AppThemeMode.dark]);
    verify(() => useCase.saveThemeMode(AppThemeMode.dark)).called(1);

    await subscription.cancel();
  });

  test('같은 값이면 아무것도 하지 않는다', () async {
    when(useCase.loadThemeMode).thenReturn(AppThemeMode.dark);
    final cubit = ThemeCubit(useCase);
    addTearDown(cubit.close);

    final emitted = <AppThemeMode>[];
    final subscription = cubit.stream.listen(emitted.add);

    await cubit.setMode(AppThemeMode.dark);

    expect(emitted, isEmpty);
    verifyNever(() => useCase.saveThemeMode(any()));

    await subscription.cancel();
  });
}
