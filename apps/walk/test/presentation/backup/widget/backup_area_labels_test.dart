import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/backup/backup_area_id.dart';
import 'package:walk/presentation/backup/widget/backup_area_labels.dart';

void main() {
  String? counts(String locale, BackupAreaId id, Map<String, int> c) =>
      lookupAppLocalizations(Locale(locale)).backupAreaCounts(id, c);

  test('wiki and alarm counts carry a unit in every language', () {
    expect(counts('ko', BackupAreaId.wiki, {'notes': 25}), '메모 25개');
    expect(counts('ko', BackupAreaId.alarm, {'alarms': 4}), '알람 4개');
    expect(counts('en', BackupAreaId.wiki, {'notes': 25}), '25 notes');
    expect(counts('en', BackupAreaId.wiki, {'notes': 1}), '1 note');
    expect(counts('en', BackupAreaId.wiki, {'notes': 0}), '0 notes');
    expect(counts('en', BackupAreaId.alarm, {'alarms': 4}), '4 alarms');
    expect(counts('en', BackupAreaId.alarm, {'alarms': 1}), '1 alarm');
    expect(counts('ja', BackupAreaId.wiki, {'notes': 25}), 'メモ 25件');
    expect(counts('ja', BackupAreaId.alarm, {'alarms': 4}), 'アラーム 4件');
  });
}
