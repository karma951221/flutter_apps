import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/data/social/unavailable_community_repository.dart';
import 'package:pawlog/domain/social/entity/walk_post_draft.dart';

FailureCode? _codeOf(Result<Object?> result) => switch (result) {
  Err(:final failure) => failure.failureCode,
  Ok() => null,
};

void main() {
  const repository = UnavailableCommunityRepository();

  test('모든 요청이 networkUnavailable 이다', () async {
    final draft = WalkPostDraft(
      localWalkId: 'w1',
      startedAt: DateTime(2026),
      duration: Duration.zero,
      distanceMeters: 0,
      dogNames: const ['콩이'],
      routePreview: const [],
    );

    for (final result in [
      await repository.fetchPage(),
      await repository.publish(draft),
      await repository.unpublish('w1'),
      await repository.updatePublished(draft),
      await repository.isPublished('w1'),
      await repository.like('p1'),
      await repository.unlike('p1'),
    ]) {
      expect(_codeOf(result), FailureCode.networkUnavailable);
    }
  });
}
