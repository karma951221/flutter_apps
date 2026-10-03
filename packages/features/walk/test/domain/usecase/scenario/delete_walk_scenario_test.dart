import 'package:core/core.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

void main() {
  late MockWalkRepository walks;
  late MockPhotoStorage storage;
  late DeleteWalkScenario scenario;

  setUp(() {
    walks = MockWalkRepository();
    storage = MockPhotoStorage();
    scenario = DeleteWalkScenario(walks, storage);
    when(() => storage.remove(any())).thenAnswer((_) async {});
  });

  final withPhotos = walk(
    photos: const [
      WalkPhoto(id: 'p1', path: 'a.jpg', position: 0),
      WalkPhoto(id: 'p2', path: 'b.jpg', position: 1),
    ],
  );

  test('행 삭제 뒤 사진 파일을 지운다', () async {
    when(() => walks.findById('w1')).thenAnswer((_) async => Ok(withPhotos));
    when(() => walks.delete('w1')).thenAnswer((_) async => const Ok(null));

    final result = await scenario('w1');

    expect(result, isA<Ok<void>>());
    verifyInOrder([
      () => walks.delete('w1'),
      () => storage.remove('a.jpg'),
      () => storage.remove('b.jpg'),
    ]);
  });

  test('행 삭제가 실패하면 파일을 지우지 않는다', () async {
    when(() => walks.findById('w1')).thenAnswer((_) async => Ok(withPhotos));
    when(
      () => walks.delete('w1'),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario('w1');

    expect(result, isA<Err<void>>());
    verifyNever(() => storage.remove(any()));
  });

  test('없는 산책이면 walkNotFound', () async {
    when(() => walks.findById('w1')).thenAnswer((_) async => const Ok(null));

    final result = await scenario('w1');

    expect((result as Err<void>).failure.failureCode, FailureCode.walkNotFound);
  });
}
