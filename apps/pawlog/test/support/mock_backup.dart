import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/backup/repository/backup_archive_codec.dart';
import 'package:pawlog/domain/backup/repository/backup_file_picker.dart';

class MockBackupArchiveCodec extends Mock implements BackupArchiveCodec {}

class MockBackupFilePicker extends Mock implements BackupFilePicker {}
