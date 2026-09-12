import 'package:daylog/app/router/routes.dart';
import 'package:daylog/core/error/failure.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/design_system/widget/app_avatar.dart';
import 'package:daylog/features/chat/domain/entity/chat_message.dart';
import 'package:daylog/features/chat/domain/entity/chat_room_summary.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/cubit/chat_room_list_cubit.dart';
import 'package:daylog/features/chat/presentation/page/chat_room_list_page.dart';
import 'package:daylog/features/chat/presentation/page/chat_room_page.dart';
import 'package:daylog/features/chat/presentation/widget/chat_room_tile.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

ChatRoomSummary _room({
  String id = 'r1',
  String? title = '대화방',
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

/// direct 방은 `title` 이 없다 — 보일 이름은 상대 닉네임에서 온다.
ChatRoomSummary _directRoom({
  String id = 'd1',
  String partnerNickname = '이웃',
  String? partnerAvatarUrl,
  int unread = 0,
}) => ChatRoomSummary(
  id: id,
  title: null,
  myNickname: '나',
  lastReadAt: DateTime.utc(2026, 8, 28),
  type: ChatRoomType.direct,
  partnerId: 'other',
  partnerNickname: partnerNickname,
  partnerAvatarUrl: partnerAvatarUrl,
  memberCount: 2,
  unreadCount: unread,
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

  /// 줄을 눌러 방으로 넘어가는 흐름은 라우터가 있어야 확인할 수 있다. 방
  /// 화면이 실제로 받은 [ChatRoomPageArgs] 를 돌려준다.
  Future<ChatRoomPageArgs Function()> pumpListWithRouter(
    WidgetTester tester,
  ) async {
    cubit = ChatRoomListCubit(useCase);
    addTearDown(cubit.close);
    await cubit.load();

    ChatRoomPageArgs? passed;
    final router = GoRouter(
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => const ChatRoomListPage()),
        GoRoute(
          path: Routes.chatRoom,
          builder: (_, state) {
            passed = ChatRoomPageArgs.fromMap(state.extra);
            return const Scaffold(body: Text('방 화면'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (_, child) =>
            BlocProvider<ChatRoomListCubit>.value(value: cubit, child: child!),
      ),
    );
    await tester.pumpAndSettle();

    return () => passed!;
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

  testWidgets('DM 줄은 방 이름 대신 상대 닉네임과 아바타를 그린다', (tester) async {
    when(
      useCase.getMyRooms,
    ).thenAnswer((_) async => Ok([_directRoom(unread: 2)]));

    await pumpList(tester);

    expect(find.text('이웃'), findsOneWidget);
    expect(find.byType(AppAvatar), findsOneWidget);
    // 둘뿐인 방이라 인원 수는 알려줄 것이 없다.
    expect(find.text('2명'), findsNothing);
    // 안읽음 배지와 미리보기는 open 방과 같은 코드를 쓴다.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('아직 대화가 없습니다'), findsOneWidget);
  });

  testWidgets('open 방 줄은 아바타 대신 방 제목과 인원 수를 그린다', (tester) async {
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room()]));

    await pumpList(tester);

    expect(find.text('대화방'), findsOneWidget);
    expect(find.text('3명'), findsOneWidget);
    expect(find.byType(AppAvatar), findsNothing);
  });

  testWidgets('DM 줄을 누르면 상대 닉네임과 direct 를 방 화면에 넘긴다', (tester) async {
    // 넘기지 않으면 방 화면이 제목 없이 뜨고 참여자 메뉴도 그대로 남는다.
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_directRoom()]));

    final passed = await pumpListWithRouter(tester);
    await tester.tap(find.text('이웃'));
    await tester.pumpAndSettle();

    expect(passed().title, '이웃');
    expect(passed().isDirect, isTrue);
  });

  testWidgets('open 방 줄을 누르면 제목만 넘기고 direct 로 열지 않는다', (tester) async {
    when(useCase.getMyRooms).thenAnswer((_) async => Ok([_room()]));

    final passed = await pumpListWithRouter(tester);
    await tester.tap(find.text('대화방'));
    await tester.pumpAndSettle();

    expect(passed().title, '대화방');
    expect(passed().isDirect, isFalse);
  });

  testWidgets('조회에 실패하면 다시 시도 버튼을 보여준다', (tester) async {
    when(
      useCase.getMyRooms,
    ).thenAnswer((_) async => const Err(Failure.network()));

    await pumpList(tester);

    expect(find.text('다시 시도'), findsOneWidget);
  });
}
