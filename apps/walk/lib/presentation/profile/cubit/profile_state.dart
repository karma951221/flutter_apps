import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/profile/profile.dart';

part 'profile_state.freezed.dart';

/// 저장된 프로필과 사진의 절대 경로(없으면 null).
@freezed
class ProfileState with _$ProfileState {
  @override
  final Profile profile;

  @override
  final String? photoPath;

  const ProfileState({this.profile = const Profile(), this.photoPath});
}

/// 편집 화면이 고른 사진 변경.
@freezed
sealed class PhotoEdit with _$PhotoEdit {
  /// 그대로 둔다.
  const factory PhotoEdit.keep() = PhotoKeep;

  /// [source] 사진으로 바꾼다.
  const factory PhotoEdit.replace(String source) = PhotoReplace;

  /// 지운다.
  const factory PhotoEdit.remove() = PhotoRemove;
}
