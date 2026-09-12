/// Supabase Auth 사용자와 profiles 행을 합친 data 전송 모델.
class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.email,
    required this.nickname,
    this.bio,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String nickname;
  final String? bio;
  final String? avatarUrl;
}
