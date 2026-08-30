import 'package:daylog/app/app.dart';
import 'package:daylog/features/preferences/domain/entity/app_language.dart';
import 'package:daylog/features/preferences/domain/usecase/preferences_use_case.dart';
import 'package:daylog/features/preferences/presentation/cubit/language_cubit.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesUseCase extends Mock implements PreferencesUseCase {}

/// `DaylogApp` 과 같은 방식으로 배선한 최소 셸.
///
/// 라우터·Supabase 를 띄우지 않고 "`locale` 이 cubit 상태를 따른다"만 확인한다.
/// 실제 앱은 여기에 `routerConfig` 와 테마만 더한 모양이다.
class _Shell extends StatelessWidget {
  const _Shell(this.cubit);

  final LanguageCubit cubit;

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: cubit,
    child: BlocBuilder<LanguageCubit, AppLanguage>(
      builder: (context, language) => MaterialApp(
        locale: language.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: resolveAppLocale,
        home: Builder(
          builder: (context) =>
              Text(AppLocalizations.of(context).settingsTitle),
        ),
      ),
    ),
  );
}

void main() {
  late _MockPreferencesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(AppLanguage.system);
  });

  setUp(() {
    useCase = _MockPreferencesUseCase();
    when(() => useCase.saveLanguage(any())).thenAnswer((_) async {});
  });

  Locale? localeOf(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale;

  testWidgets('첫 프레임의 locale 이 저장된 값이다', (tester) async {
    when(useCase.loadLanguage).thenReturn(AppLanguage.japanese);
    final cubit = LanguageCubit(useCase);
    addTearDown(cubit.close);

    await tester.pumpWidget(_Shell(cubit));

    // 기기 언어로 떴다가 바뀌는 프레임이 없다.
    expect(localeOf(tester), const Locale('ja'));
    expect(find.text('設定'), findsOneWidget);
  });

  testWidgets('cubit 이 바뀌면 locale 도 따라 바뀐다', (tester) async {
    when(useCase.loadLanguage).thenReturn(AppLanguage.system);
    final cubit = LanguageCubit(useCase);
    addTearDown(cubit.close);

    await tester.pumpWidget(_Shell(cubit));
    // 시스템은 null 이다 — Flutter 가 기기 locale 협상을 한다.
    expect(localeOf(tester), isNull);

    await cubit.setLanguage(AppLanguage.english);
    await tester.pump();
    expect(localeOf(tester), const Locale('en'));
    expect(find.text('Settings'), findsOneWidget);

    await cubit.setLanguage(AppLanguage.korean);
    await tester.pump();
    expect(localeOf(tester), const Locale('ko'));
    expect(find.text('설정'), findsOneWidget);

    await cubit.setLanguage(AppLanguage.system);
    await tester.pump();
    expect(localeOf(tester), isNull);
  });

  group('resolveAppLocale', () {
    const supported = [Locale('ko'), Locale('en'), Locale('ja')];

    test('지원하는 기기 언어는 그대로 쓴다', () {
      expect(
        resolveAppLocale(const Locale('ja'), supported),
        const Locale('ja'),
      );
      expect(
        resolveAppLocale(const Locale('ko', 'KR'), supported),
        const Locale('ko'),
      );
    });

    test('지원하지 않는 기기 언어는 영어로 떨어진다', () {
      // 기본 협상은 supportedLocales 의 첫 항목(= ko)으로 떨어진다. 프랑스어
      // 기기에 한국어를 보여주느니 영어가 낫다.
      expect(
        resolveAppLocale(const Locale('fr'), supported),
        const Locale('en'),
      );
    });

    test('기기 언어를 모르면 영어로 떨어진다', () {
      expect(resolveAppLocale(null, supported), const Locale('en'));
    });
  });
}
