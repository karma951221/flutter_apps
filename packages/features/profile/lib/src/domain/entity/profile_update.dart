import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_update.freezed.dart';

/// 내 프로필 수정에 필요한 값.
///
/// nullable 값은 해당 항목을 비우겠다는 뜻이다. 부분 수정의 모호함을 없애기 위해
/// 편집 화면은 현재 값을 포함한 전체 프로필 값을 이 명령으로 전달한다.
@freezed
class ProfileUpdate with _$ProfileUpdate {
  @override
  final String nickname;
  @override
  final String? bio;
  @override
  final String? avatarUrl;

  const ProfileUpdate({required this.nickname, this.bio, this.avatarUrl});
}
