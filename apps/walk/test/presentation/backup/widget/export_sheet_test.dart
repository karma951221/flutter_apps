import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/domain/backup/backup_service.dart';
import 'package:walk/presentation/backup/widget/export_sheet.dart';

import '../backup_test_app.dart';

void main() {
  const previews = {
    BackupAreaId.diary: AreaPreview(
      counts: {'entries': 120, 'media': 210},
      bytes: 310 * 1024 * 1024,
    ),
    BackupAreaId.chat: AreaPreview(
      counts: {'conversations': 40, 'files': 12},
      bytes: 1000,
    ),
    BackupAreaId.wiki: AreaPreview(counts: {'notes': 25}, bytes: 10),
    BackupAreaId.alarm: AreaPreview(counts: {'alarms': 4}, bytes: 10),
    BackupAreaId.settings: AreaPreview(counts: {}, bytes: 10),
    BackupAreaId.location: AreaPreview(counts: {'points': 50000}, bytes: 10),
  };

  Future<void> pump(WidgetTester tester) =>
      pumpBackupWidget(tester, ExportSheet(previews: Future.value(previews)));

  Finder area(BackupAreaId id) =>
      find.byKey(Key('backup-export-area-${id.name}'));

  bool checked(WidgetTester tester, BackupAreaId id) =>
      tester.widget<CheckboxListTile>(area(id)).value!;

  bool saveEnabled(WidgetTester tester) =>
      tester
          .widget<ButtonStyleButton>(
            find.descendant(
              of: find.byKey(const Key('backup-export-save')),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            ),
          )
          .onPressed !=
      null;

  Future<void> turnOffEncryption(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('backup-export-encrypt')));
    await tester.pumpAndSettle();
  }

  testWidgets('영역 여섯 — 위치 기록만 처음에 꺼져 있고 개수를 보인다', (tester) async {
    await pump(tester);

    for (final id in BackupAreaId.values) {
      expect(checked(tester, id), id != BackupAreaId.location, reason: '$id');
    }
    expect(find.text('기록 120 · 사진·영상 210 (310.0MB)'), findsOneWidget);
    expect(find.text('40개 · 파일 12'), findsOneWidget);
    expect(find.text('메모 25개'), findsOneWidget);
    expect(find.text('알람 4개'), findsOneWidget);
    expect(find.text('점 50,000'), findsOneWidget);
  });

  testWidgets('하나도 체크하지 않으면 저장할 수 없다', (tester) async {
    await pump(tester);
    await turnOffEncryption(tester);
    expect(saveEnabled(tester), isTrue);

    for (final id in BackupAreaId.values) {
      if (checked(tester, id)) {
        await tester.tap(area(id));
        await tester.pumpAndSettle();
      }
    }

    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('암호화는 처음에 켜져 있고, 8자 이상 · 두 번 같게 · 확인란까지 해야 저장된다', (tester) async {
    await pump(tester);
    expect(
      tester
          .widget<Switch>(
            find.descendant(
              of: find.byKey(const Key('backup-export-encrypt')),
              matching: find.byType(Switch),
            ),
          )
          .value,
      isTrue,
    );
    expect(saveEnabled(tester), isFalse);

    final pw = find.byKey(const Key('backup-export-password'));
    // 두 칸 모두 눈 버튼(가림 · 보기)이 있다.
    expect(find.byTooltip('비밀번호 보기'), findsNWidgets(2));
    final again = find.byKey(const Key('backup-export-password-again'));
    final ack = find.byKey(const Key('backup-export-forget-ack'));

    // 7자 — 짧다.
    await tester.enterText(pw, 'abcdefg');
    await tester.enterText(again, 'abcdefg');
    await tester.tap(ack);
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isFalse);

    // 8자지만 다르다.
    await tester.enterText(pw, 'abcdefgh');
    await tester.enterText(again, 'abcdefgX');
    await tester.pumpAndSettle();
    expect(find.text('비밀번호가 서로 달라요'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);

    // 같다 + 확인란 체크.
    await tester.enterText(again, 'abcdefgh');
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isTrue);

    // 확인란을 풀면 다시 꺼진다.
    await tester.tap(ack);
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('암호화를 끄면 누구나 열 수 있다고 알리고, 위치 기록을 체크하면 경고를 더한다', (tester) async {
    await pump(tester);
    const warning = Key('backup-export-location-warning');
    expect(find.text('이 파일은 누구나 열 수 있어요'), findsNothing);

    await turnOffEncryption(tester);
    expect(find.text('이 파일은 누구나 열 수 있어요'), findsOneWidget);
    expect(find.byKey(warning), findsNothing);

    await tester.tap(area(BackupAreaId.location));
    await tester.pumpAndSettle();
    expect(find.byKey(warning), findsOneWidget);
    expect(find.text('위치 기록이 암호화 없이 저장돼요'), findsOneWidget);
    // 막지는 않는다.
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('저장하면 고른 영역과 비밀번호를 돌려준다', (tester) async {
    ExportRequest? result;
    await pumpBackupWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await ExportSheet.show(
            context,
            previews: Future.value(previews),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(area(BackupAreaId.chat));
    await tester.enterText(
      find.byKey(const Key('backup-export-password')),
      'password1',
    );
    await tester.enterText(
      find.byKey(const Key('backup-export-password-again')),
      'password1',
    );
    await tester.tap(find.byKey(const Key('backup-export-forget-ack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-export-save')));
    await tester.pumpAndSettle();

    expect(result?.areas, {
      BackupAreaId.diary,
      BackupAreaId.wiki,
      BackupAreaId.alarm,
      BackupAreaId.settings,
    });
    expect(result?.password, 'password1');
  });
}
