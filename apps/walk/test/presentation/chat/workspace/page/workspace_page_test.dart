import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/lock/prefs_lock_repository.dart';
import 'package:walk/domain/chat/workspace/workspace.dart';
import 'package:walk/domain/chat/workspace/workspace_changes.dart';
import 'package:walk/domain/lock/device_auth.dart';
import 'package:walk/domain/lock/lock_repository.dart';
import 'package:walk/presentation/chat/workspace/open_workspace.dart';
import 'package:walk/presentation/chat/workspace/page/workspace_file_view_page.dart';
import 'package:walk/presentation/chat/workspace/page/workspace_page.dart';
import 'package:walk/presentation/chat/workspace/workspace_share.dart';
import 'package:walk/presentation/lock/cubit/diary_lock_cubit.dart';
import 'package:walk/presentation/lock/media_pick_guard.dart';

import '../../../../support/diary_fixtures.dart';
import '../../../../support/fake_device_auth.dart';
import '../workspace_fakes.dart';

/// 1×1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  late MemoryWorkspace ws;
  late FakeWorkspaceShare share;
  late DiaryLockCubit lock;

  final answer = workspaceFile(
    'out/20261113-1405-a.md',
    sizeBytes: 1258291, // 1.2MB
  );
  final pdf = workspaceFile(
    'inbox/20261112-090000-b.pdf',
    sizeBytes: 2048,
    modifiedAt: DateTime(2026, 11, 12, 9),
  );
  final photo = workspaceFile(
    'inbox/20261113-100000-c.png',
    sizeBytes: 300,
    modifiedAt: DateTime(2026, 11, 13, 10),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final lockRepo = PrefsLockRepository(await SharedPreferences.getInstance());
    final clock = MutableClock(DateTime(2026, 11, 13, 15));
    lock = DiaryLockCubit(lockRepo, FakeDeviceAuth(), clock, MediaPickGuard())
      ..start();
    ws = MemoryWorkspace();
    share = FakeWorkspaceShare();
    getIt
      ..registerSingleton<Clock>(clock)
      ..registerSingleton<LockRepository>(lockRepo)
      ..registerSingleton<DeviceAuth>(FakeDeviceAuth())
      ..registerSingleton<Workspace>(ws)
      ..registerSingleton<WorkspaceChanges>(WorkspaceChanges())
      ..registerSingleton<WorkspaceShare>(share);
  });

  tearDown(() async {
    await lock.close();
    await getIt.reset();
  });

  /// 잠금을 내려 주는 첫 화면. [home] 을 누르면 [onHome] 을 부른다.
  Future<void> pumpHome(
    WidgetTester tester,
    Future<void> Function(BuildContext context) onHome,
  ) async {
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
                  onPressed: () => onHome(context),
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
  }

  /// 작업 폴더 화면을 연다. 닫힐 때 받은 값은 [results].
  Future<List<WorkspaceFile?>> pump(WidgetTester tester) async {
    final results = <WorkspaceFile?>[];
    await pumpHome(tester, (context) async {
      results.add(await openWorkspace(context));
    });
    return results;
  }

  Finder row(WorkspaceFile f) => find.byKey(Key('workspace-file-${f.path}'));

  Future<void> choose(
    WidgetTester tester,
    WorkspaceFile f,
    String label,
  ) async {
    await tester.tap(
      find.descendant(of: row(f), matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('비었으면 안내 문구', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(AppBar, '작업 폴더'), findsOneWidget);
    expect(find.text('아직 파일이 없어요'), findsOneWidget);
    expect(find.text('물어보기에서 📎 로 첨부하거나 답을 파일로 저장해 보세요.'), findsOneWidget);
  });

  testWidgets('맨 위 사용량 · 두 구역(저장한 결과 먼저) · 행 부제 크기 · 날짜', (tester) async {
    ws
      ..add(answer, Uint8List(1))
      ..add(pdf, Uint8List(1))
      ..add(photo, Uint8List(1));
    await pump(tester);

    expect(find.text('3개 · 1.2MB'), findsOneWidget);
    final outTitle = find.text('저장한 결과');
    final inboxTitle = find.text('첨부한 파일');
    expect(outTitle, findsOneWidget);
    expect(inboxTitle, findsOneWidget);
    expect(
      tester.getTopLeft(outTitle).dy,
      lessThan(tester.getTopLeft(row(answer)).dy),
    );
    expect(
      tester.getTopLeft(row(answer)).dy,
      lessThan(tester.getTopLeft(inboxTitle).dy),
    );
    // inbox 는 최신순.
    expect(
      tester.getTopLeft(row(photo)).dy,
      lessThan(tester.getTopLeft(row(pdf)).dy),
    );
    expect(
      find.descendant(
        of: row(answer),
        matching: find.text('20261113-1405-a.md'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row(answer),
        matching: find.text('1.2MB · 11월 13일 14:05'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row(pdf), matching: find.text('2KB · 11월 12일 09:00')),
      findsOneWidget,
    );
  });

  testWidgets('[지우기] 는 확인 뒤에만 — 취소면 그대로, 확인이면 지우고 사라진다', (tester) async {
    ws
      ..add(answer, Uint8List(1))
      ..add(pdf, Uint8List(1));
    await pump(tester);

    await choose(tester, pdf, '지우기');
    expect(
      find.text('20261112-090000-b.pdf 을(를) 지울까요? 되돌릴 수 없어요.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(AppButton, '취소'));
    await tester.pumpAndSettle();
    expect(ws.deleted, isEmpty);
    expect(row(pdf), findsOneWidget);

    await choose(tester, pdf, '지우기');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, '지우기'),
      ),
    );
    await tester.pumpAndSettle();

    expect(ws.deleted, [pdf.path]);
    expect(row(pdf), findsNothing);
    expect(find.text('1개 · 1.2MB'), findsOneWidget);
  });

  testWidgets('[물어보기에 첨부] 는 그 파일로 닫힌다', (tester) async {
    ws.add(pdf, Uint8List(1));
    final results = await pump(tester);

    await choose(tester, pdf, '물어보기에 첨부');

    expect(find.byType(WorkspacePage), findsNothing);
    expect(results, [pdf]);
  });

  testWidgets('[공유] 는 절대 경로 · 이름으로 공유 시트를 연다', (tester) async {
    ws.add(pdf, Uint8List(1));
    await pump(tester);

    await choose(tester, pdf, '공유');

    expect(share.shared, [('/ws/${pdf.path}', pdf.name)]);
  });

  testWidgets('글 파일을 누르면 앱 안에서 평문으로 보인다', (tester) async {
    ws.add(answer, Uint8List.fromList(utf8.encode('# 제목\n\n**굵게**')));
    await pump(tester);

    await tester.tap(row(answer));
    await tester.pumpAndSettle();

    expect(find.byType(WorkspaceFileViewPage), findsOneWidget);
    expect(find.widgetWithText(AppBar, answer.name), findsOneWidget);
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(text.data, '# 제목\n\n**굵게**');
  });

  testWidgets('사진을 누르면 앱 안에서 사진으로 보인다', (tester) async {
    ws.add(photo, _png);
    await pump(tester);

    await tester.tap(row(photo));
    await tester.pumpAndSettle();

    expect(find.byType(WorkspaceFileViewPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WorkspaceFileViewPage),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(share.shared, isEmpty);
  });

  testWidgets('PDF 를 누르면 보기 대신 공유 시트', (tester) async {
    ws.add(pdf, Uint8List(1));
    await pump(tester);

    await tester.tap(row(pdf));
    await tester.pumpAndSettle();

    expect(find.byType(WorkspaceFileViewPage), findsNothing);
    expect(share.shared, [('/ws/${pdf.path}', pdf.name)]);
  });

  testWidgets('openWorkspaceFile — 없는 파일이면 열지 않고 "지운 파일이에요"', (tester) async {
    await pumpHome(
      tester,
      (context) => openWorkspaceFile(context, 'inbox/gone.pdf'),
    );

    expect(find.text('지운 파일이에요'), findsOneWidget);
    expect(find.byType(WorkspaceFileViewPage), findsNothing);
    expect(share.shared, isEmpty);
  });

  testWidgets('openWorkspaceFile — 있는 글 파일은 보기 화면으로', (tester) async {
    ws.add(answer, Uint8List.fromList(utf8.encode('답')));
    await pumpHome(
      tester,
      (context) => openWorkspaceFile(context, answer.path),
    );

    expect(find.byType(WorkspaceFileViewPage), findsOneWidget);
    expect(find.text('답'), findsOneWidget);
  });
}
