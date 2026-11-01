import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_config.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/chat/page/chat_history_page.dart';
import 'package:walk/presentation/diary/page/diary_route.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';
import 'package:walk/presentation/lock/widget/lock_secret_input.dart';

import '../../../support/diary_fixtures.dart';
import '../../../support/fake_device_auth.dart';

/// 메모리 위의 대화 목록. 목록 · 이름 바꾸기 · 삭제만 쓴다.
class _FakeHistory implements ChatHistoryRepository {
  _FakeHistory(List<Conversation> initial) : _items = [...initial];

  final List<Conversation> _items;
  final _changes = StreamController<List<Conversation>>.broadcast();

  void _emit() => _changes.add(List.unmodifiable(_items));

  @override
  Stream<List<Conversation>> conversations() async* {
    yield List.unmodifiable(_items);
    yield* _changes.stream;
  }

  @override
  Future<void> rename(String id, String title) async {
    final i = _items.indexWhere((c) => c.id == id);
    _items[i] = _items[i].copyWith(title: title.trim(), titleEdited: true);
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((c) => c.id == id);
    _emit();
  }

  @override
  Future<int> deleteAll() async {
    final n = _items.length;
    _items.clear();
    _emit();
    return n;
  }

  Future<void> close() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _now = DateTime(2026, 11, 1, 15);

Conversation _conversation(
  String id,
  String title, {
  required DateTime updatedAt,
  int turns = 1,
}) => Conversation(
  id: id,
  title: title,
  titleEdited: false,
  createdAt: updatedAt,
  updatedAt: updatedAt,
  turnCount: turns,
);

void main() {
  late _FakeHistory history;
  late DiaryLockCubit lock;
  late PrefsLockRepository lockRepo;
  late MutableClock clock;

  final today = _conversation(
    'today',
    '이번 주에 몇 번 걸었지?',
    updatedAt: DateTime(2026, 11, 1, 14, 5),
    turns: 2,
  );
  final older = _conversation(
    'older',
    '제주 여행 정리',
    updatedAt: DateTime(2026, 10, 20, 8, 30),
  );

  Future<void> setUpWith(List<Conversation> items) async {
    history = _FakeHistory(items);
    getIt.registerSingleton<ChatHistoryRepository>(history);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    clock = MutableClock(_now);
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard())
      ..start();
    getIt
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth());
  });

  tearDown(() async {
    await history.close();
    await lock.close();
    await getIt.reset();
  });

  /// 셸처럼 잠금을 내려 주는 첫 화면에서 `pushDiaryRoute<String>` 으로 목록을 연다.
  /// 닫힐 때 받은 결과를 [results] 에 넣는다.
  Future<List<String?>> pump(WidgetTester tester) async {
    final results = <String?>[];
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: lock,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => results.add(
                    await pushDiaryRoute<String>(
                      context,
                      page: (_) => const ChatHistoryPage(),
                    ),
                  ),
                  child: const Text('home'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    return results;
  }

  Finder row(String id) => find.byKey(Key('chat-history-$id'));

  Future<void> openRowMenu(WidgetTester tester, String id) async {
    await tester.tap(
      find.descendant(of: row(id), matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('최근 순 행 — 제목 · 오늘이면 시:분 · 질문 n개', (tester) async {
    await setUpWith([today, older]);
    await pump(tester);

    expect(find.widgetWithText(AppBar, '대화 목록'), findsOneWidget);
    expect(row('today'), findsOneWidget);
    expect(row('older'), findsOneWidget);
    expect(
      tester.getTopLeft(row('today')).dy,
      lessThan(tester.getTopLeft(row('older')).dy),
    );
    expect(
      find.descendant(of: row('today'), matching: find.text('이번 주에 몇 번 걸었지?')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row('today'), matching: find.text('14:05 · 질문 2개')),
      findsOneWidget,
    );
    final date = DateFormat.yMMMd('ko').format(older.updatedAt);
    expect(
      find.descendant(of: row('older'), matching: find.text('$date · 질문 1개')),
      findsOneWidget,
    );
  });

  testWidgets('행을 누르면 그 id 로 pop 한다', (tester) async {
    await setUpWith([today, older]);
    final results = await pump(tester);

    await tester.tap(find.text('제주 여행 정리'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatHistoryPage), findsNothing);
    expect(results, ['older']);
  });

  testWidgets('삭제는 확인 다이얼로그 뒤에만 — 취소면 그대로, 확인이면 사라진다', (tester) async {
    await setUpWith([today, older]);
    await pump(tester);

    await openRowMenu(tester, 'today');
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(find.text('이 대화를 지울까요?'), findsOneWidget);
    expect(find.text('질문과 답이 이 폰에서 지워져요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, '취소'));
    await tester.pumpAndSettle();
    expect(row('today'), findsOneWidget);

    await openRowMenu(tester, 'today');
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, '삭제'),
      ),
    );
    await tester.pumpAndSettle();
    expect(row('today'), findsNothing);
    expect(row('older'), findsOneWidget);
  });

  testWidgets('이름 바꾸기 — 지금 이름이 채워진 칸, 저장하면 목록 제목이 바뀐다', (tester) async {
    await setUpWith([today, older]);
    await pump(tester);

    await openRowMenu(tester, 'older');
    await tester.tap(find.text('이름 바꾸기'));
    await tester.pumpAndSettle();

    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(field).controller!.text, '제주 여행 정리');
    await tester.enterText(field, '  제주 3박 4일  ');
    await tester.tap(find.widgetWithText(AppButton, '저장'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.descendant(of: row('older'), matching: find.text('제주 3박 4일')),
      findsOneWidget,
    );
  });

  testWidgets("모두 지우기는 '대화 n개' 확인 뒤에만, 목록이 비면 메뉴가 없다", (tester) async {
    await setUpWith([today, older]);
    await pump(tester);

    final appBarMenu = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.more_vert),
    );
    await tester.tap(appBarMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('대화 모두 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('대화를 모두 지울까요?'), findsOneWidget);
    expect(find.text('대화 2개를 지워요. 사용량 기록은 남아요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, '취소'));
    await tester.pumpAndSettle();
    expect(row('today'), findsOneWidget);

    await tester.tap(appBarMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('대화 모두 지우기'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, '모두 지우기'));
    await tester.pumpAndSettle();

    expect(row('today'), findsNothing);
    expect(row('older'), findsNothing);
    expect(appBarMenu, findsNothing);
  });

  testWidgets("빈 목록이면 '저장된 대화가 없어요'", (tester) async {
    await setUpWith(const []);
    await pump(tester);

    expect(find.widgetWithText(AppPlaceholder, '저장된 대화가 없어요'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.more_vert),
      ),
      findsNothing,
    );
  });

  testWidgets('잠겨 있으면 목록이 트리에 없고 잠금 화면이 보인다', (tester) async {
    await setUpWith([today, older]);
    await lockRepo.setSecret(LockMethod.pin, '1234');
    await lockRepo.saveConfig(const LockConfig(enabled: true));
    lock.start();
    await pump(tester);

    expect(find.byType(LockSecretInput), findsOneWidget);
    expect(find.byType(ChatHistoryPage), findsNothing);
    expect(row('today'), findsNothing);

    await lock.submit('1234');
    await tester.pumpAndSettle();
    expect(row('today'), findsOneWidget);
  });
}
