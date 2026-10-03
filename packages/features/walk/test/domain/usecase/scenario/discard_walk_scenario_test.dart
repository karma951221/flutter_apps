import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

void main() {
  test('사진 파일을 지우고 tracker 를 비운다', () async {
    final tracker = MockWalkTracker();
    final storage = MockPhotoStorage();
    when(() => storage.remove(any())).thenAnswer((_) async {});
    when(() => tracker.clear()).thenAnswer((_) async {});

    await DiscardWalkScenario(tracker, storage)(photoPaths: ['a.jpg', 'b.jpg']);

    verifyInOrder([
      () => storage.remove('a.jpg'),
      () => storage.remove('b.jpg'),
      () => tracker.clear(),
    ]);
  });
}
