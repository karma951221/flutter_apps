import 'package:daylog/features/chat/data/dto/chat_room_summary_dto.dart';
import 'package:daylog/features/chat/data/mapper/chat_mapper.dart';
import 'package:daylog/features/chat/domain/entity/chat_message.dart';
import 'package:daylog/features/chat/domain/entity/chat_room_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRoomSummaryDtoMapper', () {
    test('open 방 행을 손실 없이 변환한다', () {
      final lastReadAt = DateTime.utc(2026, 8, 28);
      final dto = ChatRoomSummaryDto(
        id: 'room-1',
        title: '공개방',
        myNickname: '나',
        lastReadAt: lastReadAt,
        description: '설명',
        memberCount: 3,
        unreadCount: 2,
      );

      final summary = dto.toEntity();

      expect(summary.id, 'room-1');
      expect(summary.title, '공개방');
      expect(summary.type, ChatRoomType.open);
      expect(summary.isDirect, isFalse);
      expect(summary.displayTitle, '공개방');
      expect(summary.partnerId, isNull);
      expect(summary.partnerNickname, isNull);
      expect(summary.partnerAvatarUrl, isNull);
    });

    test('type 컬럼이 없으면 open 으로 읽는다 (뷰의 기본값과 같다)', () {
      final dto = ChatRoomSummaryDto.fromJson({
        'id': 'room-1',
        'title': '공개방',
        'my_nickname': '나',
        'last_read_at': '2026-08-28T00:00:00.000Z',
      });

      expect(dto.toEntity().type, ChatRoomType.open);
    });

    test('direct 행은 title 이 null 이고 partner 필드를 옮긴다', () {
      final dto = ChatRoomSummaryDto.fromJson({
        'id': 'room-2',
        'title': null,
        'my_nickname': '나',
        'last_read_at': '2026-08-28T00:00:00.000Z',
        'type': 'direct',
        'partner_id': 'partner-1',
        'partner_nickname': '상대',
        'partner_avatar_url': 'https://example.test/avatar.webp',
      });

      final summary = dto.toEntity();

      expect(summary.title, isNull);
      expect(summary.type, ChatRoomType.direct);
      expect(summary.isDirect, isTrue);
      expect(summary.partnerId, 'partner-1');
      expect(summary.partnerNickname, '상대');
      expect(summary.partnerAvatarUrl, 'https://example.test/avatar.webp');
      // direct 방은 title 대신 상대 닉네임을 화면 제목으로 쓴다.
      expect(summary.displayTitle, '상대');
    });

    test('마지막 메시지 종류·시스템 이벤트를 코드에서 되돌린다', () {
      final dto = ChatRoomSummaryDto.fromJson({
        'id': 'room-1',
        'title': '공개방',
        'my_nickname': '나',
        'last_read_at': '2026-08-28T00:00:00.000Z',
        'last_message_type': 'image',
        'last_message_system_event': 'join',
      });

      final summary = dto.toEntity();

      expect(summary.lastMessageType, ChatMessageType.image);
      expect(summary.lastMessageSystemEvent, ChatSystemEvent.join);
    });
  });

  group('ChatRoomSummary.asRead', () {
    test('안읽음만 0 으로 되돌리고 direct 방 필드는 잃지 않는다', () {
      final summary = ChatRoomSummary(
        id: 'room-2',
        title: null,
        myNickname: '나',
        lastReadAt: DateTime.utc(2026, 8, 28),
        type: ChatRoomType.direct,
        partnerId: 'partner-1',
        partnerNickname: '상대',
        partnerAvatarUrl: 'https://example.test/avatar.webp',
        unreadCount: 5,
      );

      final read = summary.asRead();

      expect(read.unreadCount, 0);
      expect(read.hasUnread, isFalse);
      expect(read.type, ChatRoomType.direct);
      expect(read.partnerId, 'partner-1');
      expect(read.partnerNickname, '상대');
      expect(read.partnerAvatarUrl, 'https://example.test/avatar.webp');
      expect(read.displayTitle, '상대');
    });
  });
}
