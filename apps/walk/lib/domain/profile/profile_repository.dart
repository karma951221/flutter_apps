import 'profile.dart';

/// 프로필 저장소. 이름 · 소개 · 토글은 설정 값, 사진은 앱 문서 폴더의 파일이다.
abstract interface class ProfileRepository {
  /// 동기다 — 저장소가 DI 준비 때 미리 열려 있다.
  Profile load();

  /// 이름 · 소개 · 토글을 저장한다. [profile] 의 `photo` 는 무시한다(사진은 [setPhoto] · [clearPhoto]).
  Future<void> save(Profile profile);

  /// [sourcePath] 사진을 줄인 사본(긴 변 512px 안팎, EXIF 없음)으로 저장하고 이전 사진을 지운다.
  /// 저장된 프로필을 돌려준다.
  Future<Profile> setPhoto(String sourcePath);

  /// 사진을 지운다. 저장된 프로필을 돌려준다.
  Future<Profile> clearPhoto();

  /// [profile] 사진의 절대 경로. 사진이 없으면 null.
  String? photoPath(Profile profile);
}
