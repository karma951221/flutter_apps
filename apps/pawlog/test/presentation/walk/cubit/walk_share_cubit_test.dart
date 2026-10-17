import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/core/supabase/social_availability.dart';
import 'package:pawlog/domain/social/entity/auth_session.dart';
import 'package:pawlog/presentation/walk/cubit/walk_share_cubit.dart';
import 'package:pawlog/presentation/walk/cubit/walk_share_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/mock_social_use_case.dart';
import '../../../support/social_fakes.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockSocialUseCase useCase;
  late StreamController<AuthSession?> sessions;
  late SocialAvailability available;
  AuthSession? current;

  const signInRequired = Failure.auth(
    failureCode: FailureCode.authenticationRequired,
  );

  setUp(() {
    useCase = MockSocialUseCase();
    sessions = StreamController<AuthSession?>.broadcast();
    available = SocialAvailability.available(_MockSupabaseClient());
    current = alice;
    when(() => useCase.sessions).thenAnswer((_) => sessions.stream);
    when(() => useCase.currentSession).thenAnswer((_) => current);
    when(
      () => useCase.isWalkShared('w1'),
    ).thenAnswer((_) async => const Ok(false));
    when(() => useCase.shareWalk('w1')).thenAnswer((_) async => const Ok('p1'));
    when(
      () => useCase.unshareWalk('w1'),
    ).thenAnswer((_) async => const Ok(null));
  });
  tearDown(() => sessions.close());

  WalkShareCubit build({SocialAvailability? social}) =>
      WalkShareCubit(useCase, social ?? available);

  group('load', () {
    blocTest<WalkShareCubit, WalkShareState>(
      '공유 여부를 읽는다',
      setUp: () => when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true)),
      build: build,
      act: (cubit) => cubit.load('w1'),
      expect: () => [const WalkShareState.ready(shared: true)],
    );

    blocTest<WalkShareCubit, WalkShareState>(
      '읽기가 실패하면 공유 안 됨으로 둔다(다시 공유해도 겹치지 않는다)',
      setUp: () => when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Err(Failure.network())),
      build: build,
      act: (cubit) => cubit.load('w1'),
      expect: () => [const WalkShareState.ready(shared: false)],
    );

    blocTest<WalkShareCubit, WalkShareState>(
      'Supabase 를 쓸 수 없으면 hidden 이고 서버에 묻지 않는다',
      build: () => build(social: const SocialAvailability.unavailable()),
      act: (cubit) => cubit.load('w1'),
      expect: () => [const WalkShareState.hidden()],
      verify: (_) {
        verifyNever(() => useCase.isWalkShared(any()));
        verifyNever(() => useCase.sessions);
      },
    );

    test('다른 사용자로 로그인이 바뀌면 다시 읽는다', () async {
      final cubit = build();
      await cubit.load('w1');
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));

      sessions
        ..add(alice)
        ..add(bob);
      await pumpEventQueue();

      expect(cubit.state, const WalkShareState.ready(shared: true));
      verify(() => useCase.isWalkShared('w1')).called(2);
      await cubit.close();
    });
  });

  group('toggle', () {
    blocTest<WalkShareCubit, WalkShareState>(
      '공유 안 됨이면 공유한다',
      build: build,
      act: (cubit) async {
        await cubit.load('w1');
        expect(await cubit.toggle(), WalkShareOutcome.shared);
      },
      skip: 1,
      expect: () => [
        const WalkShareState.ready(shared: false, busy: true),
        const WalkShareState.ready(shared: true),
      ],
    );

    blocTest<WalkShareCubit, WalkShareState>(
      '공유 중이면 공유를 취소한다',
      setUp: () => when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true)),
      build: build,
      act: (cubit) async {
        await cubit.load('w1');
        expect(await cubit.toggle(), WalkShareOutcome.unshared);
      },
      skip: 1,
      expect: () => [
        const WalkShareState.ready(shared: true, busy: true),
        const WalkShareState.ready(shared: false),
      ],
    );

    blocTest<WalkShareCubit, WalkShareState>(
      '실패하면 그대로 두고 failed',
      setUp: () => when(
        () => useCase.shareWalk('w1'),
      ).thenAnswer((_) async => const Err(Failure.network())),
      build: build,
      act: (cubit) async {
        await cubit.load('w1');
        expect(await cubit.toggle(), WalkShareOutcome.failed);
      },
      skip: 1,
      expect: () => [
        const WalkShareState.ready(shared: false, busy: true),
        const WalkShareState.ready(shared: false),
      ],
    );

    blocTest<WalkShareCubit, WalkShareState>(
      '로그인하지 않았으면 서버에 묻지 않고 signInRequired',
      setUp: () => current = null,
      build: build,
      act: (cubit) async {
        await cubit.load('w1');
        expect(await cubit.toggle(), WalkShareOutcome.signInRequired);
      },
      skip: 1,
      expect: () => const <WalkShareState>[],
      verify: (_) => verifyNever(() => useCase.shareWalk(any())),
    );

    blocTest<WalkShareCubit, WalkShareState>(
      '세션이 만료됐으면(authenticationRequired) signInRequired',
      setUp: () => when(
        () => useCase.shareWalk('w1'),
      ).thenAnswer((_) async => const Err(signInRequired)),
      build: build,
      act: (cubit) async {
        await cubit.load('w1');
        expect(await cubit.toggle(), WalkShareOutcome.signInRequired);
      },
    );

    test('보내는 중에 다시 누르면 무시한다', () async {
      final share = Completer<Result<String>>();
      when(() => useCase.shareWalk('w1')).thenAnswer((_) => share.future);
      final cubit = build();
      await cubit.load('w1');

      final first = cubit.toggle();
      expect(await cubit.toggle(), WalkShareOutcome.ignored);
      share.complete(const Ok('p1'));

      expect(await first, WalkShareOutcome.shared);
      verify(() => useCase.shareWalk('w1')).called(1);
      verifyNever(() => useCase.unshareWalk(any()));
      await cubit.close();
    });

    test('읽는 중이면 무시한다', () async {
      final cubit = build();
      expect(cubit.state, const WalkShareState.checking());
      expect(await cubit.toggle(), WalkShareOutcome.ignored);
      await cubit.close();
    });
  });
}
