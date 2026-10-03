import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

void main() {
  late MockWalkRepository walks;
  late MockDogRepository dogs;
  late MockPhotoStorage storage;
  late MockIdGenerator ids;
  late UpdateWalkScenario scenario;
  final now = DateTime(2026, 10, 4);

  setUpAll(registerFallbacks);

  setUp(() {
    walks = MockWalkRepository();
    dogs = MockDogRepository();
    storage = MockPhotoStorage();
    ids = MockIdGenerator();
    scenario = UpdateWalkScenario(walks, dogs, storage, ids, () => now);
    when(
      () => dogs.getAll(),
    ).thenAnswer((_) async => Ok([dog('d1'), dog('d2')]));
    when(() => walks.update(any())).thenAnswer((_) async => const Ok(null));
    when(() => storage.remove(any())).thenAnswer((_) async {});
    when(() => ids.newId()).thenReturn('new');
  });

  test('없는 산책이면 walkNotFound', () async {
    when(() => walks.findById('w1')).thenAnswer((_) async => const Ok(null));

    final result = await scenario(
      const WalkUpdate(id: 'w1', dogIds: ['d1'], photoPaths: []),
    );

    expect((result as Err<Walk>).failure.failureCode, FailureCode.walkNotFound);
  });

  test('고른 반려견이 모두 삭제된 상태면 walkDogRequired', () async {
    when(() => walks.findById('w1')).thenAnswer((_) async => Ok(walk()));

    final result = await scenario(
      const WalkUpdate(id: 'w1', dogIds: ['gone'], photoPaths: []),
    );

    expect(
      (result as Err<Walk>).failure.failureCode,
      FailureCode.walkDogRequired,
    );
    verifyNever(() => walks.update(any()));
  });

  test('빠진 사진 파일을 지운다', () async {
    when(() => walks.findById('w1')).thenAnswer(
      (_) async => Ok(
        walk(
          photos: const [
            WalkPhoto(id: 'p1', path: 'a.jpg', position: 0),
            WalkPhoto(id: 'p2', path: 'b.jpg', position: 1),
          ],
        ),
      ),
    );

    final result = await scenario(
      const WalkUpdate(
        id: 'w1',
        dogIds: ['d2'],
        memo: '메모',
        photoPaths: ['c.jpg', 'b.jpg'],
      ),
    );

    final updated = (result as Ok<Walk>).value;
    expect(updated.photos.map((p) => (p.id, p.path, p.position)), [
      ('new', 'c.jpg', 0),
      ('p2', 'b.jpg', 1),
    ]);
    expect(updated.dogs.map((d) => d.id), ['d2']);
    expect(updated.updatedAt, now);
    verify(() => storage.remove('a.jpg')).called(1);
    verifyNever(() => storage.remove('b.jpg'));
  });
}
