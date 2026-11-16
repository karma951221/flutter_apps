import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_manifest.dart';
import 'package:walk/domain/backup/backup_service.dart';
import 'package:walk/presentation/backup/widget/restore_areas_sheet.dart';

import '../backup_test_app.dart';

void main() {
  final backup = InspectedBackup(
    manifest: BackupManifest(
      format: BackupManifest.formatName,
      formatVersion: 1,
      appVersion: '1.0.0',
      createdAt: DateTime(2026, 11, 1, 21, 5),
      areas: const {
        BackupAreaId.diary: AreaManifest(
          schema: {'diary': 1},
          counts: {'entries': 120, 'media': 210},
        ),
        BackupAreaId.wiki: AreaManifest(
          schema: {'chat': 99},
          counts: {'notes': 25},
        ),
        BackupAreaId.alarm: AreaManifest(
          schema: {'alarms': 1},
          counts: {'alarms': 4},
        ),
      },
      files: const [],
    ),
    staging: Directory('staging'),
    areas: const {
      BackupAreaId.diary: AreaAvailability.ok,
      BackupAreaId.wiki: AreaAvailability.newerSchema,
      BackupAreaId.alarm: AreaAvailability.ok,
    },
  );

  Finder area(BackupAreaId id) =>
      find.byKey(Key('backup-restore-area-${id.name}'));

  /// 시트를 띄운다. 닫히면 [onClosed] 로 결과를 넘긴다.
  Future<void> open(
    WidgetTester tester, [
    void Function(Set<BackupAreaId>?)? onClosed,
  ]) async {
    await pumpBackupWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await RestoreAreasSheet.show(
              context,
              backup: backup,
            );
            onClosed?.call(result);
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('백업에 든 영역만, 기본 모두 체크 — 새 스키마 영역은 회색 · 업데이트 안내', (tester) async {
    await open(tester);

    expect(area(BackupAreaId.diary), findsOneWidget);
    expect(area(BackupAreaId.alarm), findsOneWidget);
    expect(area(BackupAreaId.chat), findsNothing);
    expect(area(BackupAreaId.location), findsNothing);

    final diary = tester.widget<CheckboxListTile>(area(BackupAreaId.diary));
    expect(diary.value, isTrue);
    expect(diary.onChanged, isNotNull);

    final wiki = tester.widget<CheckboxListTile>(area(BackupAreaId.wiki));
    expect(wiki.value, isFalse);
    expect(wiki.onChanged, isNull);
    expect(find.text('앱을 업데이트해야 복원할 수 있어요'), findsOneWidget);

    expect(find.text('기록 120 · 사진·영상 210'), findsOneWidget);
    expect(find.text('지금 데이터를 바꿉니다'), findsNWidgets(2));
  });

  testWidgets('복원을 누르면 체크한 영역을 돌려준다 · 모두 풀면 누를 수 없다', (tester) async {
    Set<BackupAreaId>? result;
    await open(tester, (r) => result = r);

    final action = find.byKey(const Key('backup-restore-areas-confirm'));
    bool enabled() =>
        tester
            .widget<ButtonStyleButton>(
              find.descendant(
                of: action,
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
            )
            .onPressed !=
        null;

    await tester.tap(area(BackupAreaId.diary));
    await tester.tap(area(BackupAreaId.alarm));
    await tester.pumpAndSettle();
    expect(enabled(), isFalse);

    await tester.tap(area(BackupAreaId.alarm));
    await tester.pumpAndSettle();
    expect(enabled(), isTrue);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(result, {BackupAreaId.alarm});
  });
}
