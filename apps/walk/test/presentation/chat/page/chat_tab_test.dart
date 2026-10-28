import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_settings.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/entity/entry_filter.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/presentation/chat/page/chat_tab.dart';
import 'package:walk/presentation/diary/viewer/story_viewer_page.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_state.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_chat_settings.dart';

class _MockSession extends Mock implements ChatSession {}

class _MockDiary extends Mock implements DiaryRepository {}

class _MockLock extends MockCubit<DiaryLockState> implements DiaryLockCubit {}

void main() {
  setUpAll(() => registerFallbackValue(const EntryFilter.all()));

  late _MockSession session;
  late _MockDiary diary;
  late FakeChatSettings settings;
  late _MockLock lock;
  late StreamController<DiaryLockState> lockStates;

  setUp(() {
    session = _MockSession();
    diary = _MockDiary();
    settings = FakeChatSettings('sk-ant-test')..consented = true;
    lock = _MockLock();
    lockStates = StreamController<DiaryLockState>.broadcast();
    whenListen(
      lock,
      lockStates.stream,
      initialState: const DiaryLockState.unlocked(),
    );
    getIt
      ..registerSingleton<ChatSession>(session)
      ..registerSingleton<ChatSettings>(settings)
      ..registerSingleton<DiaryRepository>(diary)
      ..registerSingleton<Clock>(MutableClock(diaryT0));
  });

  tearDown(() async {
    await lockStates.close();
    await getIt.reset();
  });

  Future<void> pump(WidgetTester tester, {VoidCallback? onOpenSettings}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DiaryLockCubit>.value(
          value: lock,
          child: ChatTab(active: true, onOpenSettings: onOpenSettings ?? () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void answer(String text) {
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable([
        ChatEvent.text(text),
        const ChatEvent.finished(citedEntryIds: []),
      ]),
    );
  }

  testWidgets('예시 질문 칩을 누르면 질문을 보낸다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);

    expect(find.text('지난주에 뭐 먹었지?'), findsOneWidget);
    expect(find.text('요즘 몇 시에 일어나?'), findsOneWidget);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    verify(() => session.ask('어제 뭐 했어?')).called(1);
    expect(find.text('산책을 했어요'), findsOneWidget);
  });

  testWidgets('키를 확인하는 동안 가운데에 로딩 표시를 보인다', (tester) async {
    final pending = Completer<String?>();
    getIt
      ..unregister<ChatSettings>()
      ..registerSingleton<ChatSettings>(_PendingSettings(pending.future));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DiaryLockCubit>.value(
          value: lock,
          child: ChatTab(active: true, onOpenSettings: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(Center),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('키가 없으면 설정으로 가는 버튼을 보인다', (tester) async {
    settings.key = null;
    var opened = 0;
    await pump(tester, onOpenSettings: () => opened++);

    expect(find.text('설정에서 키를 넣어 주세요'), findsOneWidget);
    await tester.tap(find.text('설정 열기'));
    expect(opened, 1);
  });

  testWidgets('동의 전이면 전송 안내와 동의 버튼을 보이고, 동의하면 시작한다', (tester) async {
    settings.consented = false;
    await pump(tester);

    expect(
      find.text(
        '질문에 필요한 일기 · 사진 · 걸음 · 기상 기록이 Anthropic 으로 전송돼요. '
        '키는 이 폰의 보안 저장소에만 있어요.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('동의하고 시작'));
    await tester.pumpAndSettle();

    expect(settings.consented, isTrue);
    expect(find.text('어제 뭐 했어?'), findsOneWidget);
  });

  testWidgets('잠겨 있으면 대화 내용이 트리에 없고, 풀면 그대로 있다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요'), findsOneWidget);

    lockStates.add(const DiaryLockState.locked(method: LockMethod.pin));
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요', skipOffstage: false), findsNothing);
    expect(find.text('어제 뭐 했어?', skipOffstage: false), findsNothing);

    lockStates.add(const DiaryLockState.unlocked());
    await tester.pumpAndSettle();
    expect(find.text('산책을 했어요'), findsOneWidget);
  });

  testWidgets('실패하면 받은 글 아래에 실패 문구를 보인다', (tester) async {
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        ChatEvent.text('반쯤'),
        ChatEvent.failed(ChatFailure.invalidKey),
      ]),
    );
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    expect(find.text('반쯤'), findsOneWidget);
    expect(find.text('키를 확인해 주세요'), findsOneWidget);
  });

  testWidgets('답하는 동안 기록을 찾으면 안내 한 줄을 보이고 전송 버튼을 끈다', (tester) async {
    final events = StreamController<ChatEvent>();
    when(() => session.ask(any())).thenAnswer((_) => events.stream);
    await pump(tester);

    await tester.enterText(find.byType(TextField), '지난 주말?');
    await tester.tap(find.byTooltip('보내기'));
    await tester.pump();
    events.add(const ChatEvent.toolStarted('search_diary'));
    await tester.pump();

    expect(find.text('기록을 찾는 중…'), findsOneWidget);
    final send = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send),
    );
    expect(send.onPressed, isNull);

    events.add(const ChatEvent.finished(citedEntryIds: []));
    await events.close();
    await tester.pumpAndSettle();
    expect(find.text('기록을 찾는 중…'), findsNothing);
  });

  testWidgets('새 대화는 대화를 비우고 예시 질문으로 돌아간다', (tester) async {
    answer('산책을 했어요');
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('새 대화'));
    await tester.pumpAndSettle();

    verify(() => session.reset()).called(1);
    expect(find.text('산책을 했어요'), findsNothing);
    expect(find.text('지난주에 뭐 먹었지?'), findsOneWidget);
  });

  testWidgets('인용 칩은 날짜와 본문 앞부분을 보이고, 누르면 그 기록부터 뷰어를 연다', (tester) async {
    final entry = DiaryEntry(
      id: 'e1',
      storyId: 's1',
      body: '한강을 따라 오래 걸었다. 바람이 차가웠지만 좋았다.',
      occurredAt: diaryT0,
      createdAt: diaryT0,
      updatedAt: diaryT0,
      media: const [],
      tags: const [],
    );
    when(() => diary.entry('e1')).thenAnswer((_) async => Ok(entry));
    when(
      () => diary.watchEntries(any()),
    ).thenAnswer((_) => Stream.value([entry]));
    when(() => session.ask(any())).thenAnswer(
      (_) => Stream.fromIterable(const [
        ChatEvent.text('한강을 걸었어요'),
        ChatEvent.finished(citedEntryIds: ['e1']),
      ]),
    );
    await pump(tester);
    await tester.tap(find.text('어제 뭐 했어?'));
    await tester.pumpAndSettle();

    final chip = find.text('10월 10일 · 한강을 따라 오래 걸었다. 바람이 차…');
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    // 조각 타이머가 끝까지 돌면 뷰어가 닫힌다 — 열리는 데까지만 흘린다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final viewer = tester.widget<StoryViewerPage>(find.byType(StoryViewerPage));
    expect(viewer.entryId, 'e1');
    expect(viewer.source, isA<EntriesSource>());
    expect((viewer.source as EntriesSource).entryIds, ['e1']);
    // 뷰어의 조각 타이머가 남지 않게 닫는다.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _PendingSettings extends FakeChatSettings {
  _PendingSettings(this.pending) : super('sk-ant-test');

  final Future<String?> pending;

  @override
  Future<String?> apiKey() => pending;
}
