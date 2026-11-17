import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/profile/profile.dart';
import '../../../domain/profile/profile_repository.dart';
import 'profile_state.dart';

export 'profile_state.dart';

/// 내 프로필. 셸이 하나 두고 설정 탭 머리 · 프로필 편집 화면이 함께 본다.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(_read(_repository));

  final ProfileRepository _repository;

  static ProfileState _read(ProfileRepository repository) {
    final profile = repository.load();
    return ProfileState(
      profile: profile,
      photoPath: repository.photoPath(profile),
    );
  }

  /// 저장소를 다시 읽는다(백업 복원 뒤 등).
  void load() => emit(_read(_repository));

  /// 사진을 먼저 바꾸고(실패하면 던지고 아무것도 저장하지 않는다) 이름 · 소개 · 토글을 저장한다.
  Future<void> save({
    required String name,
    required String bio,
    required bool shareNameWithAi,
    PhotoEdit photo = const PhotoEdit.keep(),
  }) async {
    switch (photo) {
      case PhotoKeep():
        break;
      case PhotoReplace(:final source):
        await _repository.setPhoto(source);
      case PhotoRemove():
        await _repository.clearPhoto();
    }
    await _repository.save(
      Profile(name: name, bio: bio, shareNameWithAi: shareNameWithAi),
    );
    load();
  }
}
