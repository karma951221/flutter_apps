import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/profile/prefs_profile_repository.dart';
import 'package:walk/domain/profile/profile.dart';

void main() {
  late Directory docs;
  late SharedPreferences prefs;
  late PrefsProfileRepository repo;
  late List<(String, String)> encoded;
  var now = 1000;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('profile_test');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    encoded = [];
    repo = PrefsProfileRepository.withEncoder(
      prefs,
      docs,
      encode: (src, dst) async {
        encoded.add((src, dst));
        await File(src).copy(dst);
      },
      now: () => now++,
    );
  });

  tearDown(() => docs.delete(recursive: true));

  Future<String> source(String name) async {
    final f = File('${docs.path}/$name');
    await f.writeAsString(name);
    return f.path;
  }

  test('처음엔 빈 프로필', () {
    expect(repo.load(), const Profile());
  });

  test('이름 · 소개 · 토글을 저장하고 다시 읽는다', () async {
    await repo.save(
      const Profile(name: '하늘', bio: '걷는 사람', shareNameWithAi: true),
    );
    expect(
      PrefsProfileRepository.withEncoder(prefs, docs).load(),
      const Profile(name: '하늘', bio: '걷는 사람', shareNameWithAi: true),
    );
  });

  test('빈 이름 · 소개 · 꺼진 토글은 키를 남기지 않는다', () async {
    await repo.save(
      const Profile(name: '하늘', bio: '소개', shareNameWithAi: true),
    );
    await repo.save(const Profile(name: '  '));
    expect(prefs.getKeys(), isEmpty);
  });

  test('save 는 사진을 바꾸지 않는다', () async {
    final saved = await repo.setPhoto(await source('a.jpg'));
    await repo.save(const Profile(name: '하늘', photo: 'other.jpg'));
    expect(repo.load().photo, saved.photo);
  });

  test('사진을 줄여 profile/ 에 저장하고, 바꾸면 이전 파일을 지운다', () async {
    final first = await repo.setPhoto(await source('a.jpg'));
    final firstPath = repo.photoPath(first)!;
    expect(firstPath, startsWith('${docs.path}/profile/'));
    expect(File(firstPath).readAsStringSync(), 'a.jpg');
    expect(encoded.single.$2, firstPath);

    final second = await repo.setPhoto(await source('b.jpg'));
    expect(second.photo, isNot(first.photo));
    expect(File(firstPath).existsSync(), isFalse);
    expect(File(repo.photoPath(second)!).readAsStringSync(), 'b.jpg');
    expect(repo.load().photo, second.photo);
  });

  test('줄이기가 실패하면 이전 사진을 그대로 둔다', () async {
    final first = await repo.setPhoto(await source('a.jpg'));
    final failing = PrefsProfileRepository.withEncoder(
      prefs,
      docs,
      encode: (_, _) async => throw StateError('boom'),
    );
    await expectLater(
      failing.setPhoto(await source('b.jpg')),
      throwsStateError,
    );
    expect(repo.load().photo, first.photo);
    expect(File(repo.photoPath(first)!).existsSync(), isTrue);
  });

  test('사진을 지우면 파일과 값이 없어진다', () async {
    final first = await repo.setPhoto(await source('a.jpg'));
    final cleared = await repo.clearPhoto();
    expect(cleared.photo, isNull);
    expect(repo.load().photo, isNull);
    expect(File('${docs.path}/profile/${first.photo}').existsSync(), isFalse);
  });

  test('값이 이상하면 기본값', () async {
    SharedPreferences.setMockInitialValues({
      PrefsProfileRepository.nameKey: 3,
      PrefsProfileRepository.shareNameKey: 'yes',
      PrefsProfileRepository.photoKey: '../escape.jpg',
    });
    final odd = PrefsProfileRepository.withEncoder(
      await SharedPreferences.getInstance(),
      docs,
    );
    expect(odd.load(), const Profile());
  });

  test('aiName 은 토글이 켜지고 이름이 있을 때만', () {
    expect(const Profile(name: '하늘').aiName, isNull);
    expect(const Profile(name: '  ', shareNameWithAi: true).aiName, isNull);
    expect(const Profile(name: ' 하늘 ', shareNameWithAi: true).aiName, '하늘');
  });
}
