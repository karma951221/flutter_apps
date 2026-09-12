import 'package:feature_profile/feature_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProfileDto를 domain Profile로 변환한다', () {
    final createdAt = DateTime.utc(2026, 8, 22, 9);
    final updatedAt = DateTime.utc(2026, 8, 22, 10);
    final dto = ProfileDto(
      id: 'profile-id',
      nickname: 'daylog',
      bio: '오늘의 기록',
      avatarUrl: 'https://example.com/avatar.webp',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final profile = dto.toEntity();

    expect(profile.id, 'profile-id');
    expect(profile.nickname, 'daylog');
    expect(profile.bio, '오늘의 기록');
    expect(profile.avatarUrl, 'https://example.com/avatar.webp');
    expect(profile.createdAt, createdAt);
    expect(profile.updatedAt, updatedAt);
  });
}
