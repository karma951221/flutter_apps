import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';
import '../../support/pump_app.dart';

void main() {
  late MockWalkUseCase useCase;

  setUp(() {
    useCase = MockWalkUseCase();
    getIt.registerFactory<DogListCubit>(() => DogListCubit(useCase));
  });
  tearDown(getIt.reset);

  testWidgets('빈 목록은 AppPlaceholder 와 추가 버튼을 보이고 누르면 onAddDog 를 부른다', (
    tester,
  ) async {
    when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(const Ok([])));
    var added = 0;

    await pumpApp(
      tester,
      DogListPage(onAddDog: () => added++, onOpenDog: (_) {}),
    );

    expect(find.byType(AppPlaceholder), findsOneWidget);
    await tester.tap(find.text('반려견 추가'));
    expect(added, 1);
  });

  testWidgets('강아지 2마리는 행 2개와 품종을 보이고 행을 탭하면 onOpenDog(id) 를 부른다', (
    tester,
  ) async {
    final withBreed = Dog(
      id: '1',
      name: '콩이',
      breed: '말티즈',
      createdAt: t0,
      updatedAt: t0,
    );
    when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(Ok([withBreed, dog('2')])));
    String? opened;

    await pumpApp(
      tester,
      DogListPage(onAddDog: () {}, onOpenDog: (id) => opened = id),
    );

    expect(find.byKey(const Key('walk-dog-list-tile-1')), findsOneWidget);
    expect(find.byKey(const Key('walk-dog-list-tile-2')), findsOneWidget);
    expect(find.text('말티즈'), findsOneWidget);
    expect(find.byKey(const Key('walk-dog-add-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('walk-dog-list-tile-2')));
    expect(opened, '2');
  });

  testWidgets('스트림 실패는 AppPlaceholder 와 다시 시도 버튼을 보인다', (tester) async {
    when(
      () => useCase.watchDogs(),
    ).thenAnswer((_) => Stream.value(const Err(Failure.unknown())));

    await pumpApp(tester, DogListPage(onAddDog: () {}, onOpenDog: (_) {}));

    expect(find.byType(AppPlaceholder), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
