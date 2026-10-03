import 'dart:async';

import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/pump_app.dart';

void main() {
  late MockWalkUseCase useCase;

  setUpAll(() => registerFallbackValue(const DogDraft(name: '')));
  setUp(() {
    useCase = MockWalkUseCase();
    when(() => useCase.removePhoto(any())).thenAnswer((_) async {});
    getIt.registerFactory<DogEditCubit>(() => DogEditCubit(useCase));
  });
  tearDown(getIt.reset);

  testWidgets('신규는 메뉴 없이 등록 제목을 보인다', (tester) async {
    await pumpApp(tester, DogEditPage(onDone: () {}));

    expect(find.text('반려견 등록'), findsOneWidget);
    expect(find.byKey(const Key('walk-dog-menu')), findsNothing);
  });

  testWidgets('이름을 입력하고 저장하면 onDone 을 한 번 부른다', (tester) async {
    when(() => useCase.saveDog(any())).thenAnswer((_) async => Ok(dog('1')));
    var done = 0;
    await pumpApp(tester, DogEditPage(onDone: () => done++));

    await tester.enterText(find.byKey(const Key('walk-dog-name-field')), '콩이');
    await tester.tap(find.byKey(const Key('walk-dog-save-button')));
    await tester.pumpAndSettle();

    verify(() => useCase.saveDog(const DogDraft(name: '콩이'))).called(1);
    expect(done, 1);
  });

  testWidgets('저장에 실패하면 스낵바에 실패 문구를 보인다', (tester) async {
    when(() => useCase.saveDog(any())).thenAnswer(
      (_) async => const Err(
        Failure.validation(failureCode: FailureCode.dogNameRequired),
      ),
    );
    var done = 0;
    await pumpApp(tester, DogEditPage(onDone: () => done++));

    await tester.tap(find.byKey(const Key('walk-dog-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('반려견 이름을 입력해 주세요'), findsOneWidget);
    expect(done, 0);
  });

  testWidgets('기존 반려견을 불러오는 동안에도 수정 제목을 보인다', (tester) async {
    final pending = Completer<Result<Dog?>>();
    when(() => useCase.getDog('1')).thenAnswer((_) => pending.future);
    // 스피너가 끝없이 돌아 pumpAndSettle 을 쓸 수 없다.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DogEditPage(dogId: '1', onDone: () {}),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('반려견 수정'), findsOneWidget);
    expect(find.text('반려견 등록'), findsNothing);
  });

  group('수정', () {
    setUp(() {
      when(() => useCase.getDog('1')).thenAnswer((_) async => Ok(dog('1')));
      when(
        () => useCase.deleteDog('1'),
      ).thenAnswer((_) async => const Ok(null));
    });

    Future<void> openDeleteDialog(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('walk-dog-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
    }

    testWidgets('메뉴에서 삭제를 확인하면 deleteDog 후 onDone 을 부른다', (tester) async {
      var done = 0;
      await pumpApp(tester, DogEditPage(dogId: '1', onDone: () => done++));

      expect(find.text('반려견 수정'), findsOneWidget);
      expect(find.widgetWithText(TextField, '콩이1'), findsOneWidget);

      await openDeleteDialog(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('삭제'),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => useCase.deleteDog('1')).called(1);
      expect(done, 1);
    });

    testWidgets('삭제를 취소하면 deleteDog 를 부르지 않는다', (tester) async {
      var done = 0;
      await pumpApp(tester, DogEditPage(dogId: '1', onDone: () => done++));

      await openDeleteDialog(tester);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => useCase.deleteDog(any()));
      expect(done, 0);
    });
  });
}
