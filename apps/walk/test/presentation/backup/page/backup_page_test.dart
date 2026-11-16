import 'dart:io';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/backup_manifest.dart';
import 'package:walk/domain/backup/backup_service.dart';
import 'package:walk/domain/backup/restore_notice.dart';
import 'package:walk/presentation/backup/cubit/backup_cubit.dart';
import 'package:walk/presentation/backup/page/backup_page.dart';

import '../../../support/diary_fixtures.dart';
import '../../settings/settings_harness.dart';
import '../backup_fakes.dart';

void main() {
  final h = SettingsHarness();
  late Directory tmp;
  late MockBackupService service;
  late MockBackupFiles files;
  late MockBackupFileProbe probe;
  late FakeBackupPreferences prefs;

  final inspected = InspectedBackup(
    manifest: BackupManifest(
      format: BackupManifest.formatName,
      formatVersion: 1,
      appVersion: '1.0.0',
      createdAt: DateTime(2026, 10, 1, 8, 30),
      areas: const {
        BackupAreaId.diary: AreaManifest(
          schema: {'diary': 1},
          counts: {'entries': 3, 'media': 1},
        ),
      },
      files: const [],
    ),
    staging: Directory('staging'),
    areas: const {BackupAreaId.diary: AreaAvailability.ok},
  );

  setUpAll(() {
    SettingsHarness.registerFallbacks();
    registerFallbackValue(File('x'));
    registerFallbackValue(inspected);
    registerFallbackValue(<BackupAreaId>{});
  });

  setUp(() async {
    await h.setUp();
    tmp = Directory.systemTemp.createTempSync('backup_page_test');
    service = MockBackupService();
    files = MockBackupFiles();
    probe = MockBackupFileProbe();
    prefs = FakeBackupPreferences();
    when(service.hasUndoPoint).thenAnswer((_) async => false);
    when(service.needsRecovery).thenAnswer((_) async => false);
    when(service.preview).thenAnswer((_) async => const {});
    when(files.restartApp).thenAnswer((_) async {});
    getIt.registerFactory<BackupCubit>(
      () => BackupCubit(service, files, probe, prefs, getIt<Clock>()),
    );
  });

  tearDown(() async {
    await h.tearDown();
    tmp.deleteSync(recursive: true);
  });

  const createRow = Key('backup-create');
  const restoreRow = Key('backup-restore');
  const undoRow = Key('backup-undo');

  /// cubit 이 고른 파일 · 내보낸 파일을 실제로 읽고 지우므로, 실제 입출력이 끝날 틈을 주며 그린다.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, Key row) =>
      tester.widget<AppListTile>(find.byKey(row)).enabled;

  testWidgets('마지막 백업 · 안내 문구', (tester) async {
    prefs.lastAt = diaryT0.subtract(const Duration(days: 3));
    await h.pump(tester, const BackupPage());

    expect(find.text('마지막 백업: 3일 전'), findsOneWidget);
    expect(find.text('오래됨'), findsNothing);
    expect(find.text('API 키와 잠금은 담지 않습니다. 복원 후 다시 입력하세요.'), findsOneWidget);
  });

  testWidgets('30일이 넘으면 오래됨 표시', (tester) async {
    prefs.lastAt = diaryT0.subtract(const Duration(days: 40));
    await h.pump(tester, const BackupPage());

    expect(find.text('마지막 백업: 40일 전'), findsOneWidget);
    expect(find.text('오래됨'), findsOneWidget);
  });

  testWidgets('되돌리기 행은 되돌리기 지점이 있을 때만', (tester) async {
    await h.pump(tester, const BackupPage());
    expect(find.byKey(undoRow), findsNothing);
  });

  testWidgets('되돌리기 지점이 있으면 되돌리기 행이 보인다', (tester) async {
    when(service.hasUndoPoint).thenAnswer((_) async => true);
    await h.pump(tester, const BackupPage());
    expect(find.byKey(undoRow), findsOneWidget);
  });

  testWidgets('일기가 잠겨 있으면 백업 행을 막는다', (tester) async {
    when(service.hasUndoPoint).thenAnswer((_) async => true);
    await h.lockWithPin();
    await h.pump(tester, const BackupPage());

    expect(enabled(tester, createRow), isFalse);
    expect(enabled(tester, restoreRow), isFalse);
    expect(enabled(tester, undoRow), isFalse);
    expect(find.text('일기 잠금을 풀면 백업 · 복원할 수 있어요'), findsOneWidget);

    await tester.tap(find.byKey(restoreRow));
    await settle(tester);
    verifyNever(files.open);
  });

  testWidgets('잠금이 풀려 있으면 행을 쓸 수 있다', (tester) async {
    await h.pump(tester, const BackupPage());
    expect(enabled(tester, createRow), isTrue);
    expect(enabled(tester, restoreRow), isTrue);
  });

  testWidgets('내보내기 — 시트에서 저장하면 크기를 알린다', (tester) async {
    final out = File('${tmp.path}/lifelog-backup-20261010-0900.zip')
      ..writeAsBytesSync(List.filled(2048, 0));
    when(
      () => service.export(any(), password: any(named: 'password')),
    ).thenAnswer((_) async => Ok(out));
    when(() => files.saveAs(any(), any())).thenAnswer((_) async => true);
    await h.pump(tester, const BackupPage());

    await tester.tap(find.byKey(createRow));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-export-encrypt')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-export-save')));
    await settle(tester);

    verify(
      () => service.export({
        BackupAreaId.diary,
        BackupAreaId.chat,
        BackupAreaId.wiki,
        BackupAreaId.alarm,
        BackupAreaId.settings,
      }, password: null),
    ).called(1);
    expect(find.text('백업했어요 (2KB)'), findsOneWidget);
  });

  testWidgets('복원 — 영역 고르기 → 파괴적 확인 → 결과 안내 → 다시 시작', (tester) async {
    final picked = File('${tmp.path}/picked.zip')..writeAsBytesSync([1]);
    when(files.open).thenAnswer((_) async => picked);
    when(() => probe.isEncrypted(any())).thenAnswer((_) async => false);
    when(
      () => service.inspect(any(), password: any(named: 'password')),
    ).thenAnswer((_) async => Ok(inspected));
    when(() => service.restore(any(), any())).thenAnswer(
      (_) async => const Ok({
        RestoreNotice.alarmPermissionNeeded,
        RestoreNotice.apiKeyNeeded,
      }),
    );
    await h.pump(tester, const BackupPage());

    await tester.tap(find.byKey(restoreRow));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-restore-areas-confirm')));
    await settle(tester);

    expect(find.text('복원할까요?'), findsOneWidget);
    final confirm = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('복원').last,
        matching: find.byType(TextButton),
      ),
    );
    // 파괴적 확인 — 확인 버튼이 error 색이다.
    expect(
      confirm.style?.foregroundColor?.resolve({}),
      AppTheme.light().colorScheme.error,
    );
    await tester.tap(find.text('복원').last);
    await settle(tester);

    verify(() => service.restore(inspected, {BackupAreaId.diary})).called(1);
    expect(find.text('복원을 마쳤어요'), findsOneWidget);
    expect(find.text('알람 권한을 켜 주세요.'), findsOneWidget);
    expect(find.text('물어보기 API 키를 다시 넣어 주세요.'), findsOneWidget);
    expect(find.text('위치 기록은 꺼져 있어요. 지도 설정에서 켜세요.'), findsNothing);

    await tester.tap(find.text('다시 시작'));
    await settle(tester);
    verify(files.restartApp).called(1);
  });

  testWidgets('복원 확인에서 취소하면 작업 폴더를 지운다', (tester) async {
    final picked = File('${tmp.path}/picked.zip')..writeAsBytesSync([1]);
    when(files.open).thenAnswer((_) async => picked);
    when(() => probe.isEncrypted(any())).thenAnswer((_) async => false);
    when(
      () => service.inspect(any(), password: any(named: 'password')),
    ).thenAnswer((_) async => Ok(inspected));
    when(() => service.discard(any())).thenAnswer((_) async {});
    await h.pump(tester, const BackupPage());

    await tester.tap(find.byKey(restoreRow));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-restore-areas-confirm')));
    await settle(tester);
    await tester.tap(find.text('취소'));
    await settle(tester);

    verify(() => service.discard(inspected)).called(1);
    verifyNever(() => service.restore(any(), any()));
  });

  testWidgets('암호화 파일 — 비밀번호를 묻고, 틀리면 안내와 함께 다시 묻는다', (tester) async {
    final picked = File('${tmp.path}/picked.lifelog')..writeAsBytesSync([1]);
    when(files.open).thenAnswer((_) async => picked);
    when(() => probe.isEncrypted(any())).thenAnswer((_) async => true);
    when(
      () => service.inspect(any(), password: any(named: 'password')),
    ).thenAnswer(
      (_) async => Err(BackupFailure.wrongPasswordOrCorrupt.toFailure()),
    );
    await h.pump(tester, const BackupPage());

    await tester.tap(find.byKey(restoreRow));
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('backup-password-input')),
      'nope-nope',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('backup-password-open')));
    await settle(tester);

    verify(() => service.inspect(any(), password: 'nope-nope')).called(1);
    expect(find.byKey(const Key('backup-password-input')), findsOneWidget);
    expect(find.text('비밀번호가 틀렸거나 파일이 손상됐어요'), findsOneWidget);
  });

  testWidgets('복원이 끝나지 못하면 다시 시작을 안내한다', (tester) async {
    final picked = File('${tmp.path}/picked.zip')..writeAsBytesSync([1]);
    when(files.open).thenAnswer((_) async => picked);
    when(() => probe.isEncrypted(any())).thenAnswer((_) async => false);
    when(
      () => service.inspect(any(), password: any(named: 'password')),
    ).thenAnswer((_) async => Ok(inspected));
    when(
      () => service.restore(any(), any()),
    ).thenAnswer((_) async => Err(BackupFailure.io.toFailure()));
    when(service.needsRecovery).thenAnswer((_) async => true);
    await h.pump(tester, const BackupPage());

    await tester.tap(find.byKey(restoreRow));
    await settle(tester);
    await tester.tap(find.byKey(const Key('backup-restore-areas-confirm')));
    await settle(tester);
    await tester.tap(find.text('복원').last);
    await settle(tester);

    expect(find.text('앱을 다시 시작해 주세요'), findsOneWidget);
    await tester.tap(find.text('다시 시작'));
    await settle(tester);
    verify(files.restartApp).called(1);
  });

  testWidgets('되돌리기 — 확인하면 되돌리고 결과를 보인다', (tester) async {
    when(service.hasUndoPoint).thenAnswer((_) async => true);
    when(service.undo).thenAnswer((_) async => const Ok({}));
    await h.pump(tester, const BackupPage());

    await tester.tap(find.byKey(undoRow));
    await settle(tester);
    expect(find.text('복원 전으로 되돌릴까요?'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await settle(tester);

    verify(service.undo).called(1);
    expect(find.text('복원을 마쳤어요'), findsOneWidget);
  });
}
