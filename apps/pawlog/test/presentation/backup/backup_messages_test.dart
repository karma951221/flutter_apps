import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:pawlog/domain/backup/entity/backup_import_result.dart';
import 'package:pawlog/presentation/backup/backup_messages.dart';

void main() {
  test('가져오기 결과를 스낵바 문구로 옮긴다 — 취소는 문구가 없다', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ko'));

    expect(
      backupImportMessage(const BackupImportResult.imported(2, 5), l10n),
      '반려견 2마리 · 산책 5개를 가져왔어요',
    );
    expect(
      backupImportMessage(const BackupImportResult.nothingNew(), l10n),
      '새로 가져올 기록이 없어요',
    );
    expect(
      backupImportMessage(const BackupImportResult.invalid(), l10n),
      '백업 파일을 읽지 못했어요',
    );
    expect(
      backupImportMessage(
        const BackupImportResult.failed(Failure.unknown()),
        l10n,
      ),
      '가져오지 못했어요',
    );
    expect(
      backupImportMessage(const BackupImportResult.cancelled(), l10n),
      isNull,
    );
  });

  test('영어는 복수형을 고른다', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(
      backupImportMessage(const BackupImportResult.imported(1, 1), l10n),
      'Imported 1 dog · 1 walk',
    );
    expect(
      backupImportMessage(const BackupImportResult.imported(2, 3), l10n),
      'Imported 2 dogs · 3 walks',
    );
  });
}
