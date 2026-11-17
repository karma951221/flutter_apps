import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/profile/profile.dart';
import 'package:walk/presentation/profile/cubit/profile_cubit.dart';

import '../../../support/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repo;

  setUp(
    () =>
        repo = FakeProfileRepository(const Profile(name: '하늘', photo: 'a.jpg')),
  );

  test('처음 상태는 저장된 프로필과 사진 경로', () {
    final cubit = ProfileCubit(repo);
    expect(cubit.state.profile.name, '하늘');
    expect(cubit.state.photoPath, '/profile/a.jpg');
  });

  test('save 는 값을 저장하고 사진을 그대로 둔다', () async {
    final cubit = ProfileCubit(repo);
    await cubit.save(name: ' 바다 ', bio: '소개', shareNameWithAi: true);
    expect(
      repo.profile,
      const Profile(
        name: '바다',
        bio: '소개',
        photo: 'a.jpg',
        shareNameWithAi: true,
      ),
    );
    expect(cubit.state.profile, repo.profile);
    expect(repo.setPhotoCalls, isEmpty);
  });

  test('새 사진을 주면 바꾸고, removePhoto 면 지운다', () async {
    final cubit = ProfileCubit(repo);
    await cubit.save(
      name: '하늘',
      bio: '',
      shareNameWithAi: false,
      photo: const PhotoEdit.replace('/tmp/b.jpg'),
    );
    expect(cubit.state.photoPath, '/profile/b.jpg');

    await cubit.save(
      name: '하늘',
      bio: '',
      shareNameWithAi: false,
      photo: const PhotoEdit.remove(),
    );
    expect(cubit.state.profile.photo, isNull);
    expect(cubit.state.photoPath, isNull);
  });

  test('사진 저장이 실패하면 던지고 값도 저장하지 않는다', () async {
    repo.failPhoto = true;
    final cubit = ProfileCubit(repo);
    await expectLater(
      cubit.save(
        name: '바다',
        bio: '',
        shareNameWithAi: false,
        photo: const PhotoEdit.replace('/tmp/b.jpg'),
      ),
      throwsStateError,
    );
    expect(repo.profile.name, '하늘');
    expect(cubit.state.profile.name, '하늘');
  });
}
