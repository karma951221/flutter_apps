import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_failure.dart';
import 'package:walk/domain/backup/backup_manifest.dart';
import 'package:walk/domain/backup/backup_service.dart';
import 'package:walk/domain/backup/restore_notice.dart';
import 'package:walk/presentation/backup/cubit/backup_cubit.dart';
import 'package:walk/presentation/backup/cubit/backup_state.dart';

import '../../../support/diary_fixtures.dart';
import '../backup_fakes.dart';

void main() {
  late Directory tmp;
  late MockBackupService service;
  late MockBackupFiles files;
  late MockBackupFileProbe probe;
  late FakeBackupPreferences prefs;
  late MutableClock clock;

  final inspected = InspectedBackup(
    manifest: BackupManifest(
      format: BackupManifest.formatName,
      formatVersion: 1,
      appVersion: '1.0.0',
      createdAt: DateTime(2026, 10, 1),
      areas: const {
        BackupAreaId.diary: AreaManifest(schema: {'diary': 1}),
      },
      files: const [],
    ),
    staging: Directory('staging'),
    areas: const {BackupAreaId.diary: AreaAvailability.ok},
  );

  setUpAll(() {
    registerFallbackValue(File('x'));
    registerFallbackValue(inspected);
    registerFallbackValue(<BackupAreaId>{});
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('backup_cubit_test');
    service = MockBackupService();
    files = MockBackupFiles();
    probe = MockBackupFileProbe();
    prefs = FakeBackupPreferences();
    clock = MutableClock(DateTime(2026, 11, 17, 9));
    when(service.hasUndoPoint).thenAnswer((_) async => false);
    when(service.needsRecovery).thenAnswer((_) async => false);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  BackupCubit build() => BackupCubit(service, files, probe, prefs, clock);

  File exportedFile() =>
      File('${tmp.path}/lifelog-backup-20261117-0900.lifelog')
        ..writeAsBytesSync(List.filled(2048, 1));

  group('load', () {
    blocTest<BackupCubit, BackupState>(
      '마지막 백업이 3일 전이면 3일 · 오래되지 않음 · 되돌리기 지점 있음',
      setUp: () {
        prefs.lastAt = DateTime(2026, 11, 14, 22);
        when(service.hasUndoPoint).thenAnswer((_) async => true);
      },
      build: build,
      act: (c) => c.load(),
      expect: () => [
        BackupState.idle(
          lastAt: DateTime(2026, 11, 14, 22),
          daysAgo: 3,
          hasUndo: true,
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '30일이 넘으면 오래됨',
      setUp: () => prefs.lastAt = DateTime(2026, 10, 17, 8),
      build: build,
      act: (c) => c.load(),
      expect: () => [
        BackupState.idle(
          lastAt: DateTime(2026, 10, 17, 8),
          daysAgo: 31,
          stale: true,
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '딱 30일이면 아직 오래되지 않음',
      setUp: () => prefs.lastAt = DateTime(2026, 10, 18, 9),
      build: build,
      act: (c) => c.load(),
      expect: () => [
        BackupState.idle(lastAt: DateTime(2026, 10, 18, 9), daysAgo: 30),
      ],
    );
  });

  group('export', () {
    blocTest<BackupCubit, BackupState>(
      '성공 — 만들기 → 저장 → 크기 알림 → 새 마지막 백업으로 idle, 캐시 파일은 지운다',
      setUp: () {
        when(
          () => service.export(any(), password: any(named: 'password')),
        ).thenAnswer((_) async {
          prefs.lastAt = clock.now();
          return Ok(exportedFile());
        });
        when(() => files.saveAs(any(), any())).thenAnswer((_) async => true);
      },
      build: build,
      act: (c) => c.export({BackupAreaId.diary}, password: 'password1'),
      expect: () => [
        const BackupState.working(BackupStep.exporting),
        const BackupState.working(BackupStep.saving),
        const BackupState.exported(2048),
        BackupState.idle(lastAt: DateTime(2026, 11, 17, 9), daysAgo: 0),
      ],
      verify: (_) {
        verify(
          () => service.export({BackupAreaId.diary}, password: 'password1'),
        ).called(1);
        final saved = verify(
          () => files.saveAs(captureAny(), captureAny()),
        ).captured;
        expect(saved[1], 'lifelog-backup-20261117-0900.lifelog');
        expect((saved[0] as File).existsSync(), isFalse);
      },
    );

    blocTest<BackupCubit, BackupState>(
      '저장 위치 고르기를 취소하면 알림 없이 idle',
      setUp: () {
        when(
          () => service.export(any(), password: any(named: 'password')),
        ).thenAnswer((_) async => Ok(exportedFile()));
        when(() => files.saveAs(any(), any())).thenAnswer((_) async => false);
      },
      build: build,
      act: (c) => c.export({BackupAreaId.diary}),
      expect: () => [
        const BackupState.working(BackupStep.exporting),
        const BackupState.working(BackupStep.saving),
        const BackupState.idle(),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '만들기 실패 — 실패를 알리고 idle',
      setUp: () => when(
        () => service.export(any(), password: any(named: 'password')),
      ).thenAnswer((_) async => Err(BackupFailure.noSpace.toFailure())),
      build: build,
      act: (c) => c.export({BackupAreaId.diary}),
      expect: () => [
        const BackupState.working(BackupStep.exporting),
        const BackupState.failed(BackupFailure.noSpace),
        const BackupState.idle(),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '저장 실패(채널) — 실패를 알리고 idle',
      setUp: () {
        when(
          () => service.export(any(), password: any(named: 'password')),
        ).thenAnswer((_) async => Ok(exportedFile()));
        when(
          () => files.saveAs(any(), any()),
        ).thenThrow(const BackupException(BackupFailure.io));
      },
      build: build,
      act: (c) => c.export({BackupAreaId.diary}),
      expect: () => [
        const BackupState.working(BackupStep.exporting),
        const BackupState.working(BackupStep.saving),
        const BackupState.failed(BackupFailure.io),
        const BackupState.idle(),
      ],
    );
  });

  group('restore', () {
    File opened() =>
        File('${tmp.path}/picked.zip')..writeAsBytesSync(const [1, 2, 3]);

    blocTest<BackupCubit, BackupState>(
      '파일 고르기 취소 — 아무 일 없음',
      setUp: () => when(files.open).thenAnswer((_) async => null),
      build: build,
      act: (c) => c.openBackup(),
      expect: () => const <BackupState>[],
    );

    blocTest<BackupCubit, BackupState>(
      'zip — 검사 → 영역 고르기 → 복원 → 안내와 함께 복원됨',
      setUp: () {
        when(files.open).thenAnswer((_) async => opened());
        when(() => probe.isEncrypted(any())).thenAnswer((_) async => false);
        when(
          () => service.inspect(any(), password: any(named: 'password')),
        ).thenAnswer((_) async => Ok(inspected));
        when(
          () => service.restore(any(), any()),
        ).thenAnswer((_) async => const Ok({RestoreNotice.apiKeyNeeded}));
      },
      build: build,
      act: (c) async {
        await c.openBackup();
        await c.restore({BackupAreaId.diary});
      },
      expect: () => [
        const BackupState.working(BackupStep.inspecting),
        BackupState.inspected(inspected),
        const BackupState.working(BackupStep.restoring),
        const BackupState.restored({RestoreNotice.apiKeyNeeded}),
      ],
      verify: (_) {
        verify(() => service.inspect(any(), password: null)).called(1);
        verify(
          () => service.restore(inspected, {BackupAreaId.diary}),
        ).called(1);
        // 고른 파일의 캐시 사본은 검사가 끝나면 지운다.
        expect(File('${tmp.path}/picked.zip').existsSync(), isFalse);
      },
    );

    blocTest<BackupCubit, BackupState>(
      '암호화 — 비밀번호를 묻고, 틀리면 다시 묻고, 맞으면 검사됨',
      setUp: () {
        when(files.open).thenAnswer((_) async => opened());
        when(() => probe.isEncrypted(any())).thenAnswer((_) async => true);
        when(() => service.inspect(any(), password: 'wrong-pass')).thenAnswer(
          (_) async => Err(BackupFailure.wrongPasswordOrCorrupt.toFailure()),
        );
        when(
          () => service.inspect(any(), password: 'right-pass'),
        ).thenAnswer((_) async => Ok(inspected));
      },
      build: build,
      act: (c) async {
        await c.openBackup();
        await c.submitPassword('wrong-pass');
        await c.submitPassword('right-pass');
      },
      expect: () => [
        const BackupState.passwordNeeded(),
        const BackupState.working(BackupStep.inspecting),
        const BackupState.passwordNeeded(wrong: true),
        const BackupState.working(BackupStep.inspecting),
        BackupState.inspected(inspected),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '비밀번호 묻기를 취소하면 고른 파일을 지우고 idle',
      setUp: () {
        when(files.open).thenAnswer((_) async => opened());
        when(() => probe.isEncrypted(any())).thenAnswer((_) async => true);
      },
      build: build,
      act: (c) async {
        await c.openBackup();
        await c.cancelOpen();
      },
      expect: () => [
        const BackupState.passwordNeeded(),
        const BackupState.idle(),
      ],
      verify: (_) =>
          expect(File('${tmp.path}/picked.zip').existsSync(), isFalse),
    );

    blocTest<BackupCubit, BackupState>(
      '검사 실패 — 실패를 알리고 idle',
      setUp: () {
        when(files.open).thenAnswer((_) async => opened());
        when(() => probe.isEncrypted(any())).thenAnswer((_) async => false);
        when(
          () => service.inspect(any(), password: any(named: 'password')),
        ).thenAnswer((_) async => Err(BackupFailure.notBackup.toFailure()));
      },
      build: build,
      act: (c) => c.openBackup(),
      expect: () => [
        const BackupState.working(BackupStep.inspecting),
        const BackupState.failed(BackupFailure.notBackup),
        const BackupState.idle(),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '영역 고르기에서 닫으면 작업 폴더를 지우고 idle',
      setUp: () {
        when(files.open).thenAnswer((_) async => opened());
        when(() => probe.isEncrypted(any())).thenAnswer((_) async => false);
        when(
          () => service.inspect(any(), password: any(named: 'password')),
        ).thenAnswer((_) async => Ok(inspected));
        when(() => service.discard(any())).thenAnswer((_) async {});
      },
      build: build,
      act: (c) async {
        await c.openBackup();
        await c.discard();
      },
      expect: () => [
        const BackupState.working(BackupStep.inspecting),
        BackupState.inspected(inspected),
        const BackupState.idle(),
      ],
      verify: (_) => verify(() => service.discard(inspected)).called(1),
    );

    blocTest<BackupCubit, BackupState>(
      '복원 실패 뒤 복구가 필요하면 다시 시작 안내에서 멈춘다',
      seed: () => BackupState.inspected(inspected),
      setUp: () {
        when(
          () => service.restore(any(), any()),
        ).thenAnswer((_) async => Err(BackupFailure.io.toFailure()));
        when(service.needsRecovery).thenAnswer((_) async => true);
      },
      build: build,
      act: (c) => c.restore({BackupAreaId.diary}),
      expect: () => [
        const BackupState.working(BackupStep.restoring),
        const BackupState.failed(BackupFailure.io, needsRestart: true),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '복원 실패(되돌림 성공) — 실패를 알리고 idle',
      seed: () => BackupState.inspected(inspected),
      setUp: () => when(
        () => service.restore(any(), any()),
      ).thenAnswer((_) async => Err(BackupFailure.integrity.toFailure())),
      build: build,
      act: (c) => c.restore({BackupAreaId.diary}),
      expect: () => [
        const BackupState.working(BackupStep.restoring),
        const BackupState.failed(BackupFailure.integrity),
        const BackupState.idle(),
      ],
    );
  });

  group('undo', () {
    blocTest<BackupCubit, BackupState>(
      '되돌리기 성공 — 안내와 함께 복원됨',
      setUp: () => when(
        service.undo,
      ).thenAnswer((_) async => const Ok({RestoreNotice.locationRecordingOff})),
      build: build,
      act: (c) => c.undo(),
      expect: () => [
        const BackupState.working(BackupStep.undoing),
        const BackupState.restored({RestoreNotice.locationRecordingOff}),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      '되돌리기 지점이 없으면(notFound) io 실패로 알리고 idle',
      setUp: () => when(
        service.undo,
      ).thenAnswer((_) async => const Err(Failure.notFound())),
      build: build,
      act: (c) => c.undo(),
      expect: () => [
        const BackupState.working(BackupStep.undoing),
        const BackupState.failed(BackupFailure.io),
        const BackupState.idle(),
      ],
    );
  });

  test('restartApp 은 앱을 다시 띄운다', () async {
    when(files.restartApp).thenAnswer((_) async {});
    final c = build();
    await c.restartApp();
    verify(files.restartApp).called(1);
    await c.close();
  });
}
