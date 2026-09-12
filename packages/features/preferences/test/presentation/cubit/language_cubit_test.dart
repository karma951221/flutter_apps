import 'package:feature_preferences/feature_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferencesUseCase extends Mock implements PreferencesUseCase {}

void main() {
  late _MockPreferencesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(AppLanguage.system);
  });

  setUp(() {
    useCase = _MockPreferencesUseCase();
    when(() => useCase.saveLanguage(any())).thenAnswer((_) async {});
  });

  test('초기 상태는 저장된 값이다', () {
    when(useCase.loadLanguage).thenReturn(AppLanguage.japanese);

    final cubit = LanguageCubit(useCase);

    expect(cubit.state, AppLanguage.japanese);
    addTearDown(cubit.close);
  });

  test('저장된 값이 없으면 시스템으로 시작한다', () {
    when(useCase.loadLanguage).thenReturn(AppLanguage.system);

    final cubit = LanguageCubit(useCase);

    expect(cubit.state, AppLanguage.system);
    addTearDown(cubit.close);
  });

  test('setLanguage 는 상태를 바꾸고 저장한다', () async {
    when(useCase.loadLanguage).thenReturn(AppLanguage.system);
    final cubit = LanguageCubit(useCase);
    addTearDown(cubit.close);

    final emitted = <AppLanguage>[];
    final subscription = cubit.stream.listen(emitted.add);

    await cubit.setLanguage(AppLanguage.english);

    expect(cubit.state, AppLanguage.english);
    expect(emitted, [AppLanguage.english]);
    verify(() => useCase.saveLanguage(AppLanguage.english)).called(1);

    await subscription.cancel();
  });

  test('같은 값이면 아무것도 하지 않는다', () async {
    when(useCase.loadLanguage).thenReturn(AppLanguage.korean);
    final cubit = LanguageCubit(useCase);
    addTearDown(cubit.close);

    final emitted = <AppLanguage>[];
    final subscription = cubit.stream.listen(emitted.add);

    await cubit.setLanguage(AppLanguage.korean);

    expect(emitted, isEmpty);
    verifyNever(() => useCase.saveLanguage(any()));

    await subscription.cancel();
  });

  test('시스템은 Locale 이 null 이고 나머지는 언어 코드다', () {
    // null 이면 Flutter 가 기기 locale 협상을 한다.
    expect(AppLanguage.system.locale, isNull);
    expect(AppLanguage.korean.locale, const Locale('ko'));
    expect(AppLanguage.english.locale, const Locale('en'));
    expect(AppLanguage.japanese.locale, const Locale('ja'));
  });
}
