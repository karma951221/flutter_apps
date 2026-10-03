import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fakes.dart';
import '../../support/mock_walk_use_case.dart';

PreparedImage _image() => PreparedImage(
  bytes: Uint8List.fromList([1, 2, 3]),
  width: 10,
  height: 10,
  contentType: 'image/jpeg',
  extension: 'jpg',
);

void main() {
  late MockWalkUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const DogDraft(name: ''));
    registerFallbackValue(Uint8List(0));
  });
  setUp(() {
    useCase = MockWalkUseCase();
    when(() => useCase.removePhoto(any())).thenAnswer((_) async {});
  });

  void stubStore(List<String> paths) {
    final queue = [...paths];
    when(
      () => useCase.storePhoto(
        bytes: any(named: 'bytes'),
        extension: any(named: 'extension'),
      ),
    ).thenAnswer((_) async => Ok(queue.removeAt(0)));
  }

  blocTest<DogEditCubit, DogEditState>(
    'load(null) 은 빈 폼으로 editing 이 된다',
    build: () => DogEditCubit(useCase),
    act: (cubit) => cubit.load(null),
    expect: () => [const DogEditState.editing(form: DogForm())],
  );

  blocTest<DogEditCubit, DogEditState>(
    'load(id) 는 loading 뒤 값이 채워진 editing 이 된다',
    setUp: () => when(
      () => useCase.getDog('1'),
    ).thenAnswer((_) async => Ok(dog('1', photoPath: 'a.jpg'))),
    build: () => DogEditCubit(useCase),
    act: (cubit) => cubit.load('1'),
    expect: () => [
      const DogEditState.loading(),
      DogEditState.editing(form: DogForm.fromDog(dog('1', photoPath: 'a.jpg'))),
    ],
  );

  blocTest<DogEditCubit, DogEditState>(
    '없는 강아지를 불러오면 loadFailure 가 된다',
    setUp: () =>
        when(() => useCase.getDog('1')).thenAnswer((_) async => const Ok(null)),
    build: () => DogEditCubit(useCase),
    act: (cubit) => cubit.load('1'),
    expect: () => [const DogEditState.loading(), isA<DogEditLoadFailure>()],
  );

  blocTest<DogEditCubit, DogEditState>(
    '이름 없이 저장하면 failure 를 editing 에 싣는다',
    setUp: () => when(() => useCase.saveDog(any())).thenAnswer(
      (_) async => const Err(
        Failure.validation(failureCode: FailureCode.dogNameRequired),
      ),
    ),
    build: () => DogEditCubit(useCase),
    act: (cubit) async {
      await cubit.load(null);
      await cubit.save();
    },
    expect: () => [
      const DogEditState.editing(form: DogForm()),
      const DogEditState.editing(form: DogForm(), isSaving: true),
      const DogEditState.editing(
        form: DogForm(),
        failure: Failure.validation(failureCode: FailureCode.dogNameRequired),
      ),
    ],
  );

  blocTest<DogEditCubit, DogEditState>(
    '저장에 성공하면 DogDraft 를 넘기고 saved 가 된다',
    setUp: () => when(
      () => useCase.saveDog(any()),
    ).thenAnswer((_) async => Ok(dog('1'))),
    build: () => DogEditCubit(useCase),
    act: (cubit) async {
      await cubit.load(null);
      cubit.setName('콩이');
      cubit.setBreed('');
      await cubit.save();
    },
    verify: (_) =>
        verify(() => useCase.saveDog(const DogDraft(name: '콩이'))).called(1),
    expect: () => [
      isA<DogEditEditing>(),
      isA<DogEditEditing>(),
      isA<DogEditEditing>().having((s) => s.isSaving, 'isSaving', true),
      DogEditState.saved(dog('1')),
    ],
  );

  blocTest<DogEditCubit, DogEditState>(
    '삭제하면 deleteDog 를 부르고 deleted 가 된다',
    setUp: () {
      when(() => useCase.getDog('1')).thenAnswer((_) async => Ok(dog('1')));
      when(
        () => useCase.deleteDog('1'),
      ).thenAnswer((_) async => const Ok(null));
    },
    build: () => DogEditCubit(useCase),
    act: (cubit) async {
      await cubit.load('1');
      await cubit.delete();
    },
    verify: (_) => verify(() => useCase.deleteDog('1')).called(1),
    expect: () => [
      const DogEditState.loading(),
      isA<DogEditEditing>(),
      isA<DogEditEditing>().having((s) => s.isSaving, 'isSaving', true),
      const DogEditState.deleted(),
    ],
  );

  blocTest<DogEditCubit, DogEditState>(
    '사진을 고르면 storePhoto 를 부르고 경로를 폼에 넣는다',
    setUp: () => stubStore(['new1.jpg']),
    build: () => DogEditCubit(useCase),
    act: (cubit) async {
      await cubit.load(null);
      await cubit.setPhoto(_image());
    },
    verify: (_) => verify(
      () => useCase.storePhoto(
        bytes: Uint8List.fromList([1, 2, 3]),
        extension: 'jpg',
      ),
    ).called(1),
    expect: () => [
      const DogEditState.editing(form: DogForm()),
      const DogEditState.editing(form: DogForm(photoPath: 'new1.jpg')),
    ],
  );

  blocTest<DogEditCubit, DogEditState>(
    '사진을 두 번 고르면 첫 새 파일을 지우고 둘째를 쓴다',
    setUp: () => stubStore(['new1.jpg', 'new2.jpg']),
    build: () => DogEditCubit(useCase),
    act: (cubit) async {
      await cubit.load(null);
      await cubit.setPhoto(_image());
      await cubit.setPhoto(_image());
    },
    verify: (cubit) {
      verify(() => useCase.removePhoto('new1.jpg')).called(1);
      expect((cubit.state as DogEditEditing).form.photoPath, 'new2.jpg');
    },
  );

  test('저장하지 않고 닫으면 새로 고른 사진을 지운다', () async {
    when(
      () => useCase.getDog('1'),
    ).thenAnswer((_) async => Ok(dog('1', photoPath: 'orig.jpg')));
    stubStore(['new1.jpg']);
    final cubit = DogEditCubit(useCase);
    await cubit.load('1');
    await cubit.setPhoto(_image());
    await cubit.close();

    verify(() => useCase.removePhoto('new1.jpg')).called(1);
    verifyNever(() => useCase.removePhoto('orig.jpg'));
  });

  test('저장했으면 닫아도 사진을 지우지 않는다', () async {
    when(() => useCase.saveDog(any())).thenAnswer((_) async => Ok(dog('1')));
    stubStore(['new1.jpg']);
    final cubit = DogEditCubit(useCase);
    await cubit.load(null);
    await cubit.setPhoto(_image());
    await cubit.save();
    await cubit.close();

    verifyNever(() => useCase.removePhoto(any()));
  });

  test('저장 중에 늦게 도착한 사진은 파일을 지우고 상태를 바꾸지 않는다', () async {
    final store = Completer<Result<String>>();
    when(
      () => useCase.storePhoto(
        bytes: any(named: 'bytes'),
        extension: any(named: 'extension'),
      ),
    ).thenAnswer((_) => store.future);
    when(() => useCase.saveDog(any())).thenAnswer((_) async => Ok(dog('1')));
    final cubit = DogEditCubit(useCase);
    addTearDown(cubit.close);
    await cubit.load(null);
    cubit.setName('콩이');

    final photo = cubit.setPhoto(_image());
    await cubit.save();
    store.complete(const Ok('late.jpg'));
    await photo;

    verify(() => useCase.removePhoto('late.jpg')).called(1);
    expect(cubit.state, isA<DogEditSaved>());
  });
}
