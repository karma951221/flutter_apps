import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:pawlog/domain/social/entity/walk_post_draft.dart';
import 'package:pawlog/domain/social/repository/auth_repository.dart';
import 'package:pawlog/domain/social/repository/community_repository.dart';
import 'package:pawlog/domain/social/usecase/social_use_case.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

import '../../../support/fakes.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockCommunity extends Mock implements CommunityRepository {}

const _session = AuthSession(userId: 'u1', nickname: '콩이네');

FailureCode? _codeOf(Result<Object?> result) => switch (result) {
  Err(:final failure) => failure.failureCode,
  Ok() => null,
};

/// 위도 0.0001도 ≈ 11.1 m 간격, [count] 개.
List<WalkTrackPoint> _track(int count) => [
  for (var i = 0; i < count; i++) trackPoint(37 + i * 0.0001),
];

void main() {
  late _MockAuth auth;
  late MockWalkRepository walks;
  late _MockCommunity community;
  late DefaultSocialUseCase useCase;

  setUpAll(() {
    registerFallbacks();
    registerFallbackValue(WalkPostDraft.fromWalk(walk(), const []));
  });

  setUp(() {
    auth = _MockAuth();
    walks = MockWalkRepository();
    community = _MockCommunity();
    useCase = DefaultSocialUseCase(auth, walks, community);
    when(() => auth.current).thenReturn(_session);
    when(() => walks.findById('w1')).thenAnswer((_) async => Ok(walk()));
    when(() => walks.getTrack('w1')).thenAnswer((_) async => Ok(_track(90)));
    when(
      () => community.publish(any()),
    ).thenAnswer((_) async => const Ok('p1'));
  });

  group('shareWalk', () {
    test('로그인하지 않았으면 authenticationRequired 이고 아무것도 올리지 않는다', () async {
      when(() => auth.current).thenReturn(null);

      final result = await useCase.shareWalk('w1');

      expect(_codeOf(result), FailureCode.authenticationRequired);
      verifyNever(() => walks.findById(any()));
      verifyNever(() => community.publish(any()));
    });

    test('산책과 트랙으로 초안을 만들고 앞뒤를 잘라 올린다', () async {
      final result = await useCase.shareWalk('w1');

      expect(result, isA<Ok<String>>());
      expect((result as Ok<String>).value, 'p1');
      final draft =
          verify(() => community.publish(captureAny())).captured.single
              as WalkPostDraft;
      final track = _track(90);
      expect(draft, WalkPostDraft.fromWalk(walk(), track));
      expect(draft.localWalkId, 'w1');
      expect(draft.dogNames, ['콩이d1']);
      expect(draft.routePreview, isNotEmpty);
      expect(draft.routePreview.first, isNot(track.first.point));
      expect(draft.routePreview.last, isNot(track.last.point));
    });

    test('없는 산책이면 walkNotFound', () async {
      when(() => walks.findById('w1')).thenAnswer((_) async => const Ok(null));

      expect(_codeOf(await useCase.shareWalk('w1')), FailureCode.walkNotFound);
      verifyNever(() => community.publish(any()));
    });

    test('반려견이 하나도 없으면 walkDogRequired — 서버 제약(1~10마리) 앞에서 막는다', () async {
      when(
        () => walks.findById('w1'),
      ).thenAnswer((_) async => Ok(walk(dogs: const [])));

      expect(
        _codeOf(await useCase.shareWalk('w1')),
        FailureCode.walkDogRequired,
      );
      verifyNever(() => community.publish(any()));
    });

    test('트랙을 못 읽으면 그 실패를 그대로 낸다', () async {
      when(() => walks.getTrack('w1')).thenAnswer(
        (_) async =>
            const Err(Failure.unknown(failureCode: FailureCode.invalidData)),
      );

      expect(_codeOf(await useCase.shareWalk('w1')), FailureCode.invalidData);
      verifyNever(() => community.publish(any()));
    });
  });

  group('unshareWalk', () {
    test('로그인하지 않았으면 authenticationRequired', () async {
      when(() => auth.current).thenReturn(null);

      expect(
        _codeOf(await useCase.unshareWalk('w1')),
        FailureCode.authenticationRequired,
      );
      verifyNever(() => community.unpublish(any()));
    });

    test('저장소에 넘긴다', () async {
      when(
        () => community.unpublish('w1'),
      ).thenAnswer((_) async => const Ok(null));

      expect(await useCase.unshareWalk('w1'), isA<Ok<void>>());
    });
  });

  group('isWalkShared', () {
    test('로그인하지 않았으면 서버에 묻지 않고 false', () async {
      when(() => auth.current).thenReturn(null);

      final result = await useCase.isWalkShared('w1');

      expect((result as Ok<bool>).value, isFalse);
      verifyNever(() => community.isPublished(any()));
    });

    test('로그인했으면 저장소에 묻는다', () async {
      when(
        () => community.isPublished('w1'),
      ).thenAnswer((_) async => const Ok(true));

      expect((await useCase.isWalkShared('w1') as Ok<bool>).value, isTrue);
    });
  });

  group('좋아요', () {
    test('로그인하지 않았으면 authenticationRequired', () async {
      when(() => auth.current).thenReturn(null);

      expect(
        _codeOf(await useCase.likePost('p1')),
        FailureCode.authenticationRequired,
      );
      expect(
        _codeOf(await useCase.unlikePost('p1')),
        FailureCode.authenticationRequired,
      );
      verifyNever(() => community.like(any()));
      verifyNever(() => community.unlike(any()));
    });

    test('로그인했으면 저장소에 넘긴다', () async {
      when(() => community.like('p1')).thenAnswer((_) async => const Ok(null));
      when(
        () => community.unlike('p1'),
      ).thenAnswer((_) async => const Ok(null));

      expect(await useCase.likePost('p1'), isA<Ok<void>>());
      expect(await useCase.unlikePost('p1'), isA<Ok<void>>());
    });
  });

  test('둘러보기는 로그인 없이 저장소의 페이지를 그대로 낸다', () async {
    when(() => auth.current).thenReturn(null);
    when(
      () => community.fetchPage(after: 'c1', limit: 20),
    ).thenAnswer((_) async => const Ok(CursorPage(items: [])));

    final result = await useCase.fetchCommunityPage(after: 'c1');

    expect(result, isA<Ok<CursorPage<Object?>>>());
  });
}
