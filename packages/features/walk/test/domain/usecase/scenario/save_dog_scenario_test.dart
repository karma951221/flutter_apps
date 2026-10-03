import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

void main() {
  late MockDogRepository dogs;
  late MockPhotoStorage storage;
  late MockIdGenerator ids;
  late SaveDogScenario scenario;
  final now = DateTime(2026, 10, 4);

  setUpAll(registerFallbacks);

  setUp(() {
    dogs = MockDogRepository();
    storage = MockPhotoStorage();
    ids = MockIdGenerator();
    scenario = SaveDogScenario(dogs, storage, ids, () => now);
    when(() => dogs.upsert(any())).thenAnswer((_) async => const Ok(null));
    when(() => storage.remove(any())).thenAnswer((_) async {});
    when(() => ids.newId()).thenReturn('new-id');
  });

  test('이름이 비면 dogNameRequired', () async {
    final result = await scenario(const DogDraft(name: '   '));

    expect(
      (result as Err<Dog>).failure.failureCode,
      FailureCode.dogNameRequired,
    );
    verifyNever(() => dogs.upsert(any()));
  });

  test('새 반려견은 id 와 시각을 채운다', () async {
    final result = await scenario(const DogDraft(name: ' 콩이 '));

    final saved = (result as Ok<Dog>).value;
    expect(saved.id, 'new-id');
    expect(saved.name, '콩이');
    expect(saved.createdAt, now);
    expect(saved.updatedAt, now);
  });

  test('사진을 바꾸면 옛 파일을 지운다', () async {
    when(
      () => dogs.findById('d1'),
    ).thenAnswer((_) async => Ok(dog('d1', photoPath: 'old.jpg')));

    final result = await scenario(
      const DogDraft(id: 'd1', name: '콩이', photoPath: 'new.jpg'),
    );

    final saved = (result as Ok<Dog>).value;
    expect(saved.createdAt, t0);
    expect(saved.updatedAt, now);
    verify(() => storage.remove('old.jpg')).called(1);
  });

  test('없는 반려견을 고치면 targetNotFound', () async {
    when(() => dogs.findById('d1')).thenAnswer((_) async => const Ok(null));

    final result = await scenario(const DogDraft(id: 'd1', name: '콩이'));

    expect(
      (result as Err<Dog>).failure.failureCode,
      FailureCode.targetNotFound,
    );
  });
}
