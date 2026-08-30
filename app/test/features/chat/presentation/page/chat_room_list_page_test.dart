import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/chat/domain/entity/chat_message.dart';
import 'package:daylog/features/chat/domain/entity/chat_room_summary.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/cubit/chat_room_list_cubit.dart';
import 'package:daylog/features/chat/presentation/page/chat_room_list_page.dart';
import 'package:daylog/features/chat/presentation/widget/chat_room_tile.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

ChatRoomSummary _room({
  String id = 'r1',
  String title = '대화방',
  int unread = 0,
  int members = 3,
  ChatMessageType? lastType,
  String? lastContent,
  ChatSystemEvent? lastEvent,
  DateTime? lastAt,
}) => ChatRoomSummary(
  id: id,
  title: title,
  myNickname: '나',
  lastReadAt: DateTime.utc(2026, 8, 28),
  memberCount: members,
  unreadCount: unread,
  lastMessageAt: lastAt,
  lastMessageType: lastType,
  lastMessageContent: lastContent,
  lastMessageSystemEvent: lastEvent,
);

void main() {
  late _MockChatUseCase useCase;
  late ChatRoomListCubit cubit;

  setUp(() => useCase = _MockChatUseCase());

  Future<void> pumpList(WidgetTester tester) async {
    cubit = ChatRoomListCubit(useCase);
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // 실제 앱에서는 셸(HomeShellPage)이 제공한다 — 탭 배지가 다른 탭에
        // 있을 때도 숫자를 알아야 하기 때문이다.
        home: BlocProvider<ChatRoomListCubit>.value(
          value: cubit,
          child: const ChatRoomListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('참여 중인 방이 없으면 탐색으로 보내는 안내를 보여준다', (tester) async {
    when(useCase.getMyRooms).thenAnswer((_) async => const Ok([]));

    await pumpList(tester);

    expect(find.text('참여 중인 방이 없습니다'), findsOneWidget);
    expect(find.text('방 탐색하기'), findsOneWidget);
  });

  testWidgets('방 목록에 제목과 참여자 수를 보여준다', (tester) async {
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room()]));

    await pumpList(tester);

    expect(find.text('대화방'), findsOneWidget);
    expect(find.text('3명'), findsOneWidget);
  });

  testWidgets('안읽음이 있으면 배지를 보여준다', (tester) async {
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room(unread: 7)]));

    await pumpList(tester);

    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('시스템 메시지 미리보기도 문장으로 만든다', (tester) async {
    when(useCase.getMyRooms).thenAnswer(
      (_) async => Ok([
        _room(
          lastType: ChatMessageType.system,
          lastContent: '상대',
          lastEvent: ChatSystemEvent.leave,
          lastAt: DateTime.utc(2026, 8, 28, 12),
        ),
      ]),
    );

    await pumpList(tester);

    expect(find.text('상대 님이 나갔습니다'), findsOneWidget);
  });

  testWidgets('사진 메시지 미리보기는 본문 대신 사진이라고 적는다', (tester) async {
    when(useCase.getMyRooms).thenAnswer(
      (_) async => Ok([
        _room(
          lastType: ChatMessageType.image,
          lastAt: DateTime.utc(2026, 8, 28, 12),
        ),
      ]),
    );

    await pumpList(tester);

    expect(find.text('사진'), findsOneWidget);
  });

  testWidgets('대화가 없는 방은 그렇게 적는다', (tester) async {
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room()]));

    await pumpList(tester);

    expect(find.text('아직 대화가 없습니다'), findsOneWidget);
  });

  testWidgets('방을 열 때 제목을 함께 넘긴다', (tester) async {
    // 넘기지 않으면 방 화면 AppBar 가 방 이름 대신 '채팅' 으로 뜬다.
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room()]));

    await pumpList(tester);
    final tile = tester.widget<ChatRoomTile>(find.byType(ChatRoomTile));

    expect(tile.room.title, '대화방');
  });

  testWidgets('조회에 실패하면 다시 시도 버튼을 보여준다', (tester) async {
    when(
      useCase.getMyRooms,
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpList(tester);

    expect(find.text('다시 시도'), findsOneWidget);
  });
}
