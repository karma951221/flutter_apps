import 'package:design_system/design_system.dart';
import 'package:feature_preferences/feature_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesUseCase extends Mock implements PreferencesUseCase {}

/// `DaylogApp` 과 같은 방식으로 배선한 최소 셸.
///
/// 라우터·Supabase 를 띄우지 않고 "`themeMode` 가 cubit 상태를 따른다"만
/// 확인한다. 실제 앱은 여기에 `routerConfig` 만 더한 모양이다.
class _Shell extends StatelessWidget {
  const _Shell(this.cubit);

  final ThemeCubit cubit;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: BlocBuilder<ThemeCubit, AppThemeMode>(
      builder: (context, mode) => MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode.themeMode,
        home: const SizedBox.shrink(),
      ),
    ),
  );
}

void main() {
  late _MockPreferencesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    useCase = _MockPreferencesUseCase();
    when(() => useCase.saveThemeMode(any())).thenAnswer((_) async {});
  });

  ThemeMode themeModeOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  testWidgets('첫 프레임의 themeMode 가 저장된 값이다', (tester) async {
    when(useCase.loadThemeMode).thenReturn(AppThemeMode.dark);
    final cubit = ThemeCubit(useCase);
    addTearDown(cubit.close);

    await tester.pumpWidget(_Shell(cubit));

    // 라이트로 떴다가 바뀌는 프레임이 없다.
    expect(themeModeOf(tester), ThemeMode.dark);
  });

  testWidgets('cubit 이 바뀌면 themeMode 도 따라 바뀐다', (tester) async {
    when(useCase.loadThemeMode).thenReturn(AppThemeMode.system);
    final cubit = ThemeCubit(useCase);
    addTearDown(cubit.close);

    await tester.pumpWidget(_Shell(cubit));
    expect(themeModeOf(tester), ThemeMode.system);

    await cubit.setMode(AppThemeMode.light);
    await tester.pump();
    expect(themeModeOf(tester), ThemeMode.light);

    await cubit.setMode(AppThemeMode.dark);
    await tester.pump();
    expect(themeModeOf(tester), ThemeMode.dark);
  });

  test('세 모드 모두 material 의 ThemeMode 로 옮겨진다', () {
    expect(AppThemeMode.system.themeMode, ThemeMode.system);
    expect(AppThemeMode.light.themeMode, ThemeMode.light);
    expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
  });
}
