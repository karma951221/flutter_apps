import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daylog/core/di/injection.dart';
import 'package:daylog/core/pagination/cursor_page.dart';
import 'package:daylog/core/result/result.dart';
import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:daylog/features/auth/domain/entity/app_user.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_event.dart';
import 'package:daylog/features/auth/presentation/bloc/auth_state.dart';
import 'package:daylog/features/chat/domain/entity/chat_message.dart';
import 'package:daylog/features/chat/domain/entity/chat_participant.dart';
import 'package:daylog/features/chat/domain/usecase/chat_use_case.dart';
import 'package:daylog/features/chat/presentation/bloc/chat_room_bloc.dart';
import 'package:daylog/features/chat/presentation/page/chat_room_page.dart';
import 'package:daylog/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatUseCase extends Mock implements ChatUseCase {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _me = AppUser(id: 'me', email: 'me@example.test', nickname: '카르마');
const _roomId = 'room-1';

ChatMessage _message(
  String id, {
  String? senderId = 'other',
  String? content = '안녕',
  ChatMessageType type = ChatMessageType.text,
  ChatSystemEvent? systemEvent,
}) => ChatMessage(
  id: id,
  roomId: _roomId,
  type: type,
  createdAt: DateTime.utc(2026, 8, 28, 10),
  senderId: senderId,
  content: content,
  systemEvent: systemEvent,
);

void main() {
  late _MockChatUseCase useCase;
  late _MockAuthBloc authBloc;
  late StreamController<ChatMessage> incoming;

  setUp(() {
    useCase = _MockChatUseCase();
    authBloc = _MockAuthBloc();
    incoming = StreamController<ChatMessage>.broadcast();

    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(_me),
    );
    when(() => useCase.messageStream(any())).thenAnswer((_) => incoming.stream);
    when(() => useCase.disposeMessageStream(any())).thenAnswer((_) async {});
    when(() => useCase.newMessageId()).thenAnswer((_) => 'new-1');
    when(() => useCase.getParticipants(any())).thenAnswer(
      (_) async => Ok([
        ChatParticipant(
          userId: 'other',
          nickname: '상대',
          joinedAt: DateTime.utc(2026, 8, 28),
        ),
      ]),
    );
    when(
      () => useCase.markRead(
        roomId: any(named: 'roomId'),
        at: any(named: 'at'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    when(
      () => useCase.sendMessage(
        id: any(named: 'id'),
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer((_) async => const Ok(null));

    getIt
      ..registerFactory<ChatRoomBloc>(() => ChatRoomBloc(useCase))
      ..registerSingleton<ChatUseCase>(useCase);
  });

  tearDown(() async {
    await incoming.close();
    await getIt.reset();
  });

  void stubMessages(List<ChatMessage> messages) {
    when(
      () => useCase.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer((_) async => Ok(CursorPage(items: messages)));
  }

  Future<void> pumpRoom(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        // ko 가 ARB template 언어라 원문이 곧 기대값이다 (계획서).
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const ChatRoomPage(roomId: _roomId, title: '테스트 방'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('받은 메시지에 방별 닉네임이 붙는다', (tester) async {
    stubMessages([_message('m1')]);

    await pumpRoom(tester);

    expect(find.text('테스트 방'), findsOneWidget);
    expect(find.text('안녕'), findsOneWidget);
    // 프로필 닉네임이 아니라 이 방에서 쓰는 이름이다.
    expect(find.text('상대'), findsOneWidget);
  });

  testWidgets('시스템 메시지는 DB 의 키로 문장을 만들어 보여준다', (tester) async {
    stubMessages([
      _message(
        's1',
        senderId: null,
        content: '상대',
        type: ChatMessageType.system,
        systemEvent: ChatSystemEvent.join,
      ),
    ]);

    await pumpRoom(tester);

    // DB 에는 'join' 과 닉네임만 있고 문장은 ARB 가 만든다.
    expect(find.text('상대 님이 들어왔습니다'), findsOneWidget);
  });

  testWidgets('입력하고 보내면 버블이 즉시 뜨고 입력칸이 비워진다', (tester) async {
    stubMessages([]);

    await pumpRoom(tester);

    await tester.enterText(find.byType(TextField), '반가워');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();

    expect(find.text('반가워'), findsOneWidget);
    // 낙관적 버블이라 서버 응답을 기다리지 않는다.
    expect(find.text('보내는 중'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '',
    );
  });

  testWidgets('빈 입력은 보내지 않는다', (tester) async {
    stubMessages([]);

    await pumpRoom(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();

    verifyNever(
      () => useCase.sendMessage(
        id: any(named: 'id'),
        roomId: any(named: 'roomId'),
        content: any(named: 'content'),
      ),
    );
  });

  testWidgets('메시지가 없으면 안내를 보여준다', (tester) async {
    stubMessages([]);

    await pumpRoom(tester);

    expect(find.text('첫 메시지를 남겨보세요'), findsOneWidget);
  });

  testWidgets('방 메뉴에 참여자와 나가기가 있다', (tester) async {
    stubMessages([]);

    await pumpRoom(tester);
    await tester.tap(find.byTooltip('방 메뉴'));
    await tester.pumpAndSettle();

    expect(find.text('참여자'), findsOneWidget);
    expect(find.text('방 나가기'), findsOneWidget);
  });

  testWidgets('나가기는 확인을 거쳐야 실행된다', (tester) async {
    stubMessages([]);
    when(
      () => useCase.leaveRoom(any()),
    ).thenAnswer((_) async => const Ok(null));

    await pumpRoom(tester);
    await tester.tap(find.byTooltip('방 메뉴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('방 나가기'));
    await tester.pumpAndSettle();

    expect(find.text('방에서 나갈까요?'), findsOneWidget);
    // 다이얼로그를 띄운 것만으로는 나가지 않는다.
    verifyNever(() => useCase.leaveRoom(any()));

    await tester.tap(find.widgetWithText(TextButton, '나가기'));
    await tester.pumpAndSettle();

    verify(() => useCase.leaveRoom(_roomId)).called(1);
  });

  testWidgets('내 메시지를 길게 누르면 삭제가 뜬다', (tester) async {
    stubMessages([_message('m1', senderId: 'me', content: '내 말')]);

    await pumpRoom(tester);
    await tester.longPress(find.text('내 말'));
    await tester.pumpAndSettle();

    expect(find.text('삭제'), findsOneWidget);
    expect(find.text('신고'), findsNothing);
  });

  testWidgets('남의 메시지를 길게 누르면 신고가 뜬다', (tester) async {
    stubMessages([_message('m1')]);

    await pumpRoom(tester);
    await tester.longPress(find.text('안녕'));
    await tester.pumpAndSettle();

    expect(find.text('신고'), findsOneWidget);
    expect(find.text('삭제'), findsNothing);
  });

  testWidgets('실시간으로 온 메시지가 재조회 없이 목록에 붙는다', (tester) async {
    stubMessages([]);

    await pumpRoom(tester);
    expect(find.text('새 메시지'), findsNothing);

    incoming.add(_message('rt', content: '새 메시지'));
    await tester.pumpAndSettle();

    expect(find.text('새 메시지'), findsOneWidget);
    // 목록을 다시 읽지 않는다 — 처음 한 번뿐이다.
    verify(
      () => useCase.getMessages(
        roomId: any(named: 'roomId'),
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).called(1);
  });
}
