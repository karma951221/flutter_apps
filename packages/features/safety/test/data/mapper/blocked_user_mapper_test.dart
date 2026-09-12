import 'package:feature_safety/feature_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BlockedUserDto 를 domain BlockedUser 로 변환한다', () {
    final createdAt = DateTime.utc(2026, 8, 25, 9);
    final dto = BlockedUserDto(
      id: 'user-1',
      nickname: 'daylog',
      avatarUrl: 'https://example.com/avatar.webp',
      createdAt: createdAt,
    );

    final blockedUser = dto.toEntity();

    expect(blockedUser.id, 'user-1');
    expect(blockedUser.nickname, 'daylog');
    expect(blockedUser.avatarUrl, 'https://example.com/avatar.webp');
    expect(blockedUser.blockedAt, createdAt);
  });

  test('avatarUrl 이 없으면 null 로 변환된다', () {
    final dto = BlockedUserDto(
      id: 'user-2',
      nickname: 'no-avatar',
      createdAt: DateTime.utc(2026, 8, 25, 10),
    );

    expect(dto.toEntity().avatarUrl, isNull);
  });
}
