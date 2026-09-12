import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:daylog/features/profile/domain/entity/profile.dart';
import 'package:daylog/features/profile/domain/entity/profile_update.dart';
import 'package:daylog/features/profile/domain/usecase/profile_use_case.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:daylog/features/profile/presentation/cubit/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileUseCase extends Mock implements ProfileUseCase {}

Profile _profile({String id = 'me', String nickname = '카르마'}) => Profile(
  id: id,
  nickname: nickname,
  createdAt: DateTime.utc(2026, 8, 22, 9),
  updatedAt: DateTime.utc(2026, 8, 22, 9),
);

void main() {
  late _MockProfileUseCase useCase;

  setUpAll(() => registerFallbackValue(const ProfileUpdate(nickname: '')));

  setUp(() => useCase = _MockProfileUseCase());

  blocTest<ProfileCubit, ProfileState>(
    'userId 없이 부르면 내 프로필을 읽는다',
    setUp: () =>
        when(useCase.getMyProfile).thenAnswer((_) async => Ok(_profile())),
    build: () => ProfileCubit(useCase),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.profile?.id, 'me');
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.failure, isNull);
      verify(useCase.getMyProfile).called(1);
      verifyNever(() => useCase.getProfile(any()));
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'userId 를 주면 그 사용자의 프로필을 읽는다',
    setUp: () => when(
      () => useCase.getProfile('other'),
    ).thenAnswer((_) async => Ok(_profile(id: 'other', nickname: '이웃'))),
    build: () => ProfileCubit(useCase),
    act: (cubit) => cubit.load(userId: 'other'),
    verify: (cubit) {
      expect(cubit.state.profile?.id, 'other');
      expect(cubit.state.profile?.nickname, '이웃');
      // 남의 프로필 화면에서 내 프로필을 읽으면 화면 주인이 바뀐다.
      verify(() => useCase.getProfile('other')).called(1);
      verifyNever(useCase.getMyProfile);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    '내 프로필 조회 실패는 실패로 남긴다',
    setUp: () => when(
      useCase.getMyProfile,
    ).thenAnswer((_) async => const Err(Failure.network())),
    build: () => ProfileCubit(useCase),
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.profile, isNull);
      expect(cubit.state.isLoading, isFalse);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    '타인 프로필 조회 실패도 실패로 남긴다',
    setUp: () => when(() => useCase.getProfile('other')).thenAnswer(
      (_) async => const Err(Failure.notFound(message: '프로필이 없습니다')),
    ),
    build: () => ProfileCubit(useCase),
    act: (cubit) => cubit.load(userId: 'other'),
    verify: (cubit) {
      expect(cubit.state.failure, isA<NotFoundFailure>());
      expect(cubit.state.profile, isNull);
      expect(cubit.state.isLoading, isFalse);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    '저장은 내 프로필만 갱신하고 결과를 상태에 담는다',
    setUp: () => when(
      () => useCase.updateMyProfile(any()),
    ).thenAnswer((_) async => Ok(_profile(nickname: '바뀐이름'))),
    build: () => ProfileCubit(useCase),
    act: (cubit) => cubit.save(const ProfileUpdate(nickname: '바뀐이름')),
    verify: (cubit) {
      expect(cubit.state.profile?.nickname, '바뀐이름');
      expect(cubit.state.isSaving, isFalse);
      verify(
        () => useCase.updateMyProfile(const ProfileUpdate(nickname: '바뀐이름')),
      ).called(1);
    },
  );

  group('화면을 떠난 뒤 도착한 결과', () {
    // 화면을 떠나면 BlocProvider 가 cubit 을 닫는다. 그때 진행 중이던 요청이
    // 늦게 끝나 emit 하면 bloc 이 예외를 던진다.
    test('조회 중 닫혀도 예외 없이 끝난다', () async {
      final response = Completer<Result<Profile>>();
      when(useCase.getMyProfile).thenAnswer((_) => response.future);
      final cubit = ProfileCubit(useCase);

      final loading = cubit.load();
      await cubit.close();
      response.complete(Ok(_profile()));

      await expectLater(loading, completes);
    });

    test('저장 중 닫혀도 예외 없이 끝난다', () async {
      final response = Completer<Result<Profile>>();
      when(
        () =>
            useCase.updateMyProfile(any(), newAvatar: any(named: 'newAvatar')),
      ).thenAnswer((_) => response.future);
      final cubit = ProfileCubit(useCase);

      final saving = cubit.save(const ProfileUpdate(nickname: '바뀐이름'));
      await cubit.close();
      response.complete(Ok(_profile(nickname: '바뀐이름')));

      await expectLater(saving, completes);
    });
  });

  group('닉네임 사전 확인', () {
    // 디바운스가 지나 조회까지 끝나기를 기다린다.
    Future<void> settle() => Future<void>.delayed(
      nicknameCheckDebounce + const Duration(milliseconds: 100),
    );

    Future<ProfileCubit> loadedCubit() async {
      when(useCase.getMyProfile).thenAnswer((_) async => Ok(_profile()));
      final cubit = ProfileCubit(useCase);
      await cubit.load();
      return cubit;
    }

    test('입력이 멎은 뒤 한 번만 조회하고 사용 가능을 알린다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Ok(true));
      final cubit = await loadedCubit();

      cubit.checkNickname('새이');
      cubit.checkNickname('새이름');
      expect(cubit.state.nicknameCheck, isA<NicknameCheckChecking>());
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckAvailable>());
      verify(() => useCase.isNicknameAvailable('새이름')).called(1);
      verifyNever(() => useCase.isNicknameAvailable('새이'));
      await cubit.close();
    });

    test('이미 쓰는 닉네임이면 중복으로 알린다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Ok(false));
      final cubit = await loadedCubit();

      cubit.checkNickname('  겹치는이름  ');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckTaken>());
      verify(() => useCase.isNicknameAvailable('겹치는이름')).called(1);
      await cubit.close();
    });

    test('지금 쓰고 있는 닉네임은 조회하지 않는다', () async {
      final cubit = await loadedCubit();

      cubit.checkNickname('카르마');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckIdle>());
      verifyNever(() => useCase.isNicknameAvailable(any()));
      await cubit.close();
    });

    test('형식이 어긋난 닉네임은 조회하지 않는다', () async {
      final cubit = await loadedCubit();

      cubit.checkNickname('짧');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckIdle>());
      verifyNever(() => useCase.isNicknameAvailable(any()));
      await cubit.close();
    });

    test('확인에 실패하면 아무 말도 하지 않는다', () async {
      when(
        () => useCase.isNicknameAvailable(any()),
      ).thenAnswer((_) async => const Err(Failure.network()));
      final cubit = await loadedCubit();

      cubit.checkNickname('새이름');
      await settle();

      expect(cubit.state.nicknameCheck, isA<NicknameCheckIdle>());
      await cubit.close();
    });
  });
}
