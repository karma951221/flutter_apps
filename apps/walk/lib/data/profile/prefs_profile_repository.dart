import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/profile/profile.dart';
import '../../domain/profile/profile_repository.dart';

/// [src] 사진을 줄여 [dst] 에 JPEG 로 쓴다.
typedef ProfilePhotoEncoder = Future<void> Function(String src, String dst);

/// 프로필 — 값은 `SharedPreferences`, 사진은 `<appDocs>/profile/avatar-<millis>.jpg`.
@LazySingleton(as: ProfileRepository)
class PrefsProfileRepository implements ProfileRepository {
  PrefsProfileRepository(
    SharedPreferences prefs,
    @Named('appDocs') Directory docs,
  ) : this.withEncoder(prefs, docs);

  @visibleForTesting
  PrefsProfileRepository.withEncoder(
    this._prefs,
    Directory docs, {
    ProfilePhotoEncoder encode = _compress,
    int Function()? now,
  }) : _dir = Directory('${docs.path}/$folder'),
       _encode = encode,
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const nameKey = 'profile.name';
  static const bioKey = 'profile.bio';
  static const photoKey = 'profile.photo';
  static const shareNameKey = 'profile.shareNameWithAi';

  /// 앱 문서 폴더 아래 사진 폴더 이름. 백업 영역도 쓴다.
  static const folder = 'profile';

  /// 사진의 짧은 변 목표(px).
  static const photoSize = 512;

  final SharedPreferences _prefs;
  final Directory _dir;
  final ProfilePhotoEncoder _encode;
  final int Function() _now;

  /// 사진 폴더 — 백업 영역이 복사한다.
  Directory get photoDir => _dir;

  @override
  Profile load() {
    final name = _prefs.get(nameKey);
    final bio = _prefs.get(bioKey);
    final photo = _prefs.get(photoKey);
    final share = _prefs.get(shareNameKey);
    return Profile(
      name: name is String ? name : '',
      bio: bio is String ? bio : '',
      photo: photo is String && isSafeFileName(photo) ? photo : null,
      shareNameWithAi: share is bool && share,
    );
  }

  @override
  Future<void> save(Profile profile) async {
    // 기본값은 키를 지운다 — 프로필을 만든 적 없는 기기의 설정이 그대로다(백업 되돌리기 비교).
    Future<void> put(String key, String value) =>
        value.isEmpty ? _prefs.remove(key) : _prefs.setString(key, value);
    await put(nameKey, profile.name.trim());
    await put(bioKey, profile.bio.trim());
    if (profile.shareNameWithAi) {
      await _prefs.setBool(shareNameKey, true);
    } else {
      await _prefs.remove(shareNameKey);
    }
  }

  @override
  Future<Profile> setPhoto(String sourcePath) async {
    final before = load().photo;
    await _dir.create(recursive: true);
    final name = 'avatar-${_now()}.jpg';
    final target = File('${_dir.path}/$name');
    try {
      await _encode(sourcePath, target.path);
    } catch (_) {
      if (target.existsSync()) await target.delete();
      rethrow;
    }
    await _prefs.setString(photoKey, name);
    if (before != null && before != name) await _deleteQuietly(before);
    return load();
  }

  @override
  Future<Profile> clearPhoto() async {
    final before = load().photo;
    await _prefs.remove(photoKey);
    if (before != null) await _deleteQuietly(before);
    return load();
  }

  @override
  String? photoPath(Profile profile) {
    final photo = profile.photo;
    return photo == null ? null : '${_dir.path}/$photo';
  }

  Future<void> _deleteQuietly(String name) async {
    try {
      final file = File('${_dir.path}/$name');
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // 남은 파일은 다음 교체 · 지우기에 영향이 없다.
    }
  }

  /// 폴더를 벗어나지 않는 파일 이름인지.
  static bool isSafeFileName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains(r'\') &&
      name != '.' &&
      name != '..';

  static Future<void> _compress(String src, String dst) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      src,
      dst,
      minWidth: photoSize,
      minHeight: photoSize,
      quality: 85,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );
    if (result == null) throw StateError('profile photo compress failed');
  }
}
