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
      '읽기가 실패하면(시간 제한 포함) 항목을 숨긴다 — 짐작으로 "공유" 를 보이지 않는다',
      setUp: () => when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Err(Failure.network())),
      build: build,
      act: (cubit) => cubit.load('w1'),
      expect: () => [const WalkShareState.hidden()],
    );

    test('읽기 실패 뒤 로그인이 바뀌면 다시 읽어 항목을 되살린다', () async {
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');
      expect(cubit.state, const WalkShareState.hidden());

      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));
      sessions.add(bob);
      await pumpEventQueue();

      expect(cubit.state, const WalkShareState.ready(shared: true));
    });

    test('읽기 실패 뒤 다시 load(상세 다시 열기)하면 다시 읽는다', () async {
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');

      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(false));
      await cubit.load('w1');

      expect(cubit.state, const WalkShareState.ready(shared: false));
    });

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

    test('보내는 사이 로그인이 바뀌면 새 사용자의 읽기 결과를 덮어쓰지 않는다', () async {
      final share = Completer<Result<String>>();
      when(() => useCase.shareWalk('w1')).thenAnswer((_) => share.future);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');

      final pending = cubit.toggle();
      // bob 으로 바뀌었다 — bob 은 이 산책을 공유하지 않았다.
      sessions.add(bob);
      await pumpEventQueue();
      expect(cubit.state, const WalkShareState.ready(shared: false));

      share.complete(const Ok('p1'));
      expect(await pending, WalkShareOutcome.shared);

      expect(cubit.state, const WalkShareState.ready(shared: false));
    });

    test('보내는 사이 로그인이 바뀌고 실패해도 busy 로 되돌리지 않는다', () async {
      final share = Completer<Result<String>>();
      when(() => useCase.shareWalk('w1')).thenAnswer((_) => share.future);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));

      final pending = cubit.toggle();
      sessions.add(bob);
      await pumpEventQueue();
      share.complete(const Err(Failure.network()));
      expect(await pending, WalkShareOutcome.failed);

      expect(cubit.state, const WalkShareState.ready(shared: true));
    });

    test('읽는 중이면 무시한다', () async {
      final cubit = build();
      expect(cubit.state, const WalkShareState.checking());
      expect(await cubit.toggle(), WalkShareOutcome.ignored);
      await cubit.close();
    });
  });

  group('unshareForDelete', () {
    test('공유 중이면 공유 취소를 보내고 성공하면 true', () async {
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');

      expect(await cubit.unshareForDelete(), isTrue);
      verify(() => useCase.unshareWalk('w1')).called(1);
    });

    test('공유 취소가 실패하면 false', () async {
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Ok(true));
      when(
        () => useCase.unshareWalk('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');

      expect(await cubit.unshareForDelete(), isFalse);
    });

    test('공유 안 됨을 확인했으면 서버에 묻지 않는다', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');

      expect(await cubit.unshareForDelete(), isTrue);
      verifyNever(() => useCase.unshareWalk(any()));
    });

    test('공유 여부를 모르면(읽기 실패) 공유 취소를 보낸다', () async {
      when(
        () => useCase.isWalkShared('w1'),
      ).thenAnswer((_) async => const Err(Failure.network()));
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load('w1');

      expect(await cubit.unshareForDelete(), isTrue);
      verify(() => useCase.unshareWalk('w1')).called(1);
    });

    test('로그인하지 않았거나 Supabase 를 쓸 수 없으면 서버에 묻지 않는다', () async {
      current = null;
      final signedOut = build();
      addTearDown(signedOut.close);
      await signedOut.load('w1');
      expect(await signedOut.unshareForDelete(), isTrue);

      current = alice;
      final unavailable = build(social: const SocialAvailability.unavailable());
      addTearDown(unavailable.close);
      await unavailable.load('w1');
      expect(await unavailable.unshareForDelete(), isTrue);

      verifyNever(() => useCase.unshareWalk(any()));
    });
  });
}
