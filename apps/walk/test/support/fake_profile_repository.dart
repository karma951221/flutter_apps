import 'package:walk/domain/profile/profile.dart';
import 'package:walk/domain/profile/profile_repository.dart';

/// 메모리 프로필 저장소. 사진은 원본 경로를 그대로 "저장"한다.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile = const Profile()]);

  Profile profile;

  /// 다음 [setPhoto] 를 실패시킨다.
  bool failPhoto = false;
  final setPhotoCalls = <String>[];

  @override
  Profile load() => profile;

  @override
  Future<void> save(Profile next) async {
    profile = next.copyWith(
      name: next.name.trim(),
      bio: next.bio.trim(),
      photo: profile.photo,
    );
  }

  @override
  Future<Profile> setPhoto(String sourcePath) async {
    setPhotoCalls.add(sourcePath);
    if (failPhoto) throw StateError('photo');
    return profile = profile.copyWith(photo: sourcePath.split('/').last);
  }

  @override
  Future<Profile> clearPhoto() async => profile = profile.copyWith(photo: null);

  @override
  String? photoPath(Profile p) =>
      p.photo == null ? null : '/profile/${p.photo}';
}
