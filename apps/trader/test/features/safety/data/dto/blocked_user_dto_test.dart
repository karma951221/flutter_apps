import 'package:daylog/features/safety/data/dto/blocked_user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocked_users 뷰 행 JSON 을 파싱한다', () {
    final dto = BlockedUserDto.fromJson({
      'id': 'user-1',
      'nickname': 'daylog',
      'avatar_url': 'https://example.com/avatar.webp',
      'created_at': '2026-08-25T09:00:00.000Z',
    });

    expect(dto.id, 'user-1');
    expect(dto.nickname, 'daylog');
    expect(dto.avatarUrl, 'https://example.com/avatar.webp');
    expect(dto.createdAt, DateTime.parse('2026-08-25T09:00:00.000Z'));
  });

  test('avatar_url 이 없어도 파싱된다', () {
    final dto = BlockedUserDto.fromJson({
      'id': 'user-2',
      'nickname': 'no-avatar',
      'avatar_url': null,
      'created_at': '2026-08-25T09:00:00.000Z',
    });

    expect(dto.avatarUrl, isNull);
  });
}
