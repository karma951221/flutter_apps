import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/backup/channel_backup_files.dart';
import 'package:walk/domain/backup/backup_failure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ChannelBackupFiles.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  void answer(Object? Function(MethodCall call) reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return reply(call);
    });
  }

  Matcher failsWith(BackupFailure failure) => throwsA(
    isA<BackupException>().having((e) => e.failure, 'failure', failure),
  );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('채널 이름은 com.karma.walk/backup_file', () {
    expect(ChannelBackupFiles.channelName, 'com.karma.walk/backup_file');
  });

  group('saveAs', () {
    test('경로 · 이름 · zip mime 을 넘기고 저장했으면 true', () async {
      answer((_) => true);

      final saved = await ChannelBackupFiles().saveAs(
        File('/cache/backup_export/a.zip'),
        'lifelog-backup-20261117-0930.zip',
      );

      expect(saved, isTrue);
      expect(calls.single.method, 'saveAs');
      expect(calls.single.arguments, {
        'path': '/cache/backup_export/a.zip',
        'name': 'lifelog-backup-20261117-0930.zip',
        'mime': 'application/zip',
      });
    });

    test('암호화 파일(.lifelog)은 application/octet-stream', () async {
      answer((_) => true);
      await ChannelBackupFiles().saveAs(
        File('/c/a.lifelog'),
        'lifelog-backup-20261117-0930.lifelog',
      );
      expect(
        (calls.single.arguments as Map)['mime'],
        'application/octet-stream',
      );
    });

    test('취소(false · null)는 false', () async {
      answer((_) => false);
      expect(
        await ChannelBackupFiles().saveAs(File('/c/a.zip'), 'a.zip'),
        isFalse,
      );
      answer((_) => null);
      expect(
        await ChannelBackupFiles().saveAs(File('/c/a.zip'), 'a.zip'),
        isFalse,
      );
    });

    test('공간 부족은 noSpace', () async {
      answer((_) => throw PlatformException(code: 'no_space'));
      expect(
        ChannelBackupFiles().saveAs(File('/c/a.zip'), 'a.zip'),
        failsWith(BackupFailure.noSpace),
      );
    });

    test('다른 오류는 io', () async {
      answer((_) => throw PlatformException(code: 'failed', message: 'boom'));
      expect(
        ChannelBackupFiles().saveAs(File('/c/a.zip'), 'a.zip'),
        failsWith(BackupFailure.io),
      );
    });

    test('채널이 없으면 io', () {
      expect(
        ChannelBackupFiles().saveAs(File('/c/a.zip'), 'a.zip'),
        failsWith(BackupFailure.io),
      );
    });
  });

  group('open', () {
    test('복사본 경로를 File 로 돌려준다', () async {
      answer((_) => '/cache/backup_import/picked');

      final file = await ChannelBackupFiles().open();

      expect(calls.single.method, 'open');
      expect(calls.single.arguments, isNull);
      expect(file?.path, '/cache/backup_import/picked');
    });

    test('취소(null)는 null', () async {
      answer((_) => null);
      expect(await ChannelBackupFiles().open(), isNull);
    });

    test('빈 경로도 null', () async {
      answer((_) => '');
      expect(await ChannelBackupFiles().open(), isNull);
    });

    test('공간 부족은 noSpace', () async {
      answer((_) => throw PlatformException(code: 'no_space'));
      expect(ChannelBackupFiles().open(), failsWith(BackupFailure.noSpace));
    });

    test('다른 오류는 io', () async {
      answer((_) => throw PlatformException(code: 'failed'));
      expect(ChannelBackupFiles().open(), failsWith(BackupFailure.io));
    });
  });

  group('restartApp', () {
    test('restart 를 부른다', () async {
      answer((_) => null);
      await ChannelBackupFiles().restartApp();
      expect(calls.single.method, 'restart');
    });

    test('오류는 io', () async {
      answer((_) => throw PlatformException(code: 'failed'));
      expect(ChannelBackupFiles().restartApp(), failsWith(BackupFailure.io));
    });
  });
}
