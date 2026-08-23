import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
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
}
