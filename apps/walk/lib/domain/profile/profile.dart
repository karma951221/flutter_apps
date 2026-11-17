import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';

/// 내 프로필 — 설정 탭 머리에 보인다. 잠금 밖이다.
@freezed
class Profile with _$Profile {
  /// 이름 최대 길이.
  static const maxName = 20;

  /// 한 줄 소개 최대 길이.
  static const maxBio = 60;

  @override
  final String name;

  @override
  final String bio;

  /// 앱 문서 폴더 `profile/` 아래 사진 파일 이름. 없으면 null.
  @override
  final String? photo;

  /// 물어보기 시스템 프롬프트에 [name] 을 넣는다. 기본 끔 — 켜면 이름이 Claude · GPT 로 간다.
  @override
  final bool shareNameWithAi;

  const Profile({
    this.name = '',
    this.bio = '',
    this.photo,
    this.shareNameWithAi = false,
  });

  /// AI 에 보낼 이름. 끄거나 이름이 비었으면 null.
  String? get aiName {
    final trimmed = name.trim();
    return shareNameWithAi && trimmed.isNotEmpty ? trimmed : null;
  }
}
