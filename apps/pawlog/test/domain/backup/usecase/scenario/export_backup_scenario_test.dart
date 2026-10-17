import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/backup/entity/backup_data.dart';
import 'package:pawlog/domain/backup/policy/backup_codec.dart';
import 'package:pawlog/domain/backup/usecase/scenario/export_backup_scenario.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';

import '../../../../support/fakes.dart';
import '../../../../support/mock_backup.dart';
import '../../../../support/mock_walk_file_sharer.dart';

void main() {
  late MockDogRepository dogs;
  late MockWalkRepository walks;
  late MockPhotoStorage photos;
  late MockBackupArchiveCodec archive;
  late MockWalkFileSharer sharer;
  late Directory root;
  late ExportBackupScenario scenario;

  final now = DateTime(2026, 10, 7, 23, 50);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    dogs = MockDogRepository();
    walks = MockWalkRepository();
    photos = MockPhotoStorage();
    archive = MockBackupArchiveCodec();
    sharer = MockWalkFileSharer();
    root = Directory.systemTemp.createTempSync('export_backup_test');
    scenario = ExportBackupScenario(
      dogs,
      walks,
      photos,
      archive,
      sharer,
      FakeClock.fixed(now),
    );
    when(() => photos.resolve(any())).thenAnswer(
      (i) => File('${root.path}/${i.positionalArguments.first as String}'),
    );
    when(
      () => archive.pack(
        json: any(named: 'json'),
        photos: any(named: 'photos'),
      ),
    ).thenAnswer((_) async => Uint8List.fromList([9, 9]));
    when(
      () => sharer.shareBytes(
        fileName: any(named: 'fileName'),
        bytes: any(named: 'bytes'),
        mimeType: any(named: 'mimeType'),
      ),
    ).thenAnswer((_) async => const Ok(null));
  });

  tearDown(() => root.deleteSync(recursive: true));

  void writePhoto(String path, List<int> bytes) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  }

  final d1 = dog('d1', photoPath: 'dogs/d1.jpg');
  final w1 = walk(
    dogs: [d1],
    photos: const [
      WalkPhoto(id: 'p1', path: 'walks/a.jpg', position: 0),
      WalkPhoto(id: 'p2', path: 'walks/missing.jpg', position: 1),
    ],
  );
  final points = [trackPoint(37.5), trackPoint(37.6)];

  test('json · 사진 · 파일 이름 · mime 으로 공유한다. 없는 사진 파일은 빠진다', () async {
    writePhoto('dogs/d1.jpg', [1, 2]);
    writePhoto('walks/a.jpg', [3]);
    when(() => dogs.getAll()).thenAnswer((_) async => Ok([d1]));
    when(() => walks.watchAll()).thenAnswer((_) => Stream.value(Ok([w1])));
    when(() => walks.getTrack('w1')).thenAnswer((_) async => Ok(points));

    final result = await scenario();

    expect(result, isA<Ok<void>>());
    final expectedJson = BackupCodec.encode(
      BackupData(
        exportedAt: now,
        dogs: [d1],
        walks: [BackupWalk(walk: w1, points: points)],
      ),
    );
    final captured = verify(
      () => archive.pack(
        json: captureAny(named: 'json'),
        photos: captureAny(named: 'photos'),
      ),
    ).captured;
    expect(captured[0], expectedJson);
    final packed = captured[1] as Map<String, Uint8List>;
    expect(packed.keys, unorderedEquals(['dogs/d1.jpg', 'walks/a.jpg']));
    expect(packed['dogs/d1.jpg'], [1, 2]);
    expect(packed['walks/a.jpg'], [3]);
    verify(
      () => sharer.shareBytes(
        fileName: 'pawlog-backup-2026-10-07.zip',
        bytes: Uint8List.fromList([9, 9]),
        mimeType: 'application/zip',
      ),
    ).called(1);
  });

  test('반려견을 못 읽으면 공유하지 않고 Err', () async {
    when(
      () => dogs.getAll(),
    ).thenAnswer((_) async => const Err(Failure.unknown()));
    when(() => walks.watchAll()).thenAnswer((_) => Stream.value(Ok([w1])));

    final result = await scenario();

    expect(result, isA<Err<void>>());
    verifyNever(
      () => sharer.shareBytes(
        fileName: any(named: 'fileName'),
        bytes: any(named: 'bytes'),
        mimeType: any(named: 'mimeType'),
      ),
    );
  });

  test('경로를 못 읽으면 공유하지 않고 Err', () async {
    when(() => dogs.getAll()).thenAnswer((_) async => Ok([d1]));
    when(() => walks.watchAll()).thenAnswer((_) => Stream.value(Ok([w1])));
    when(
      () => walks.getTrack('w1'),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, isA<Err<void>>());
    verifyNever(
      () => archive.pack(
        json: any(named: 'json'),
        photos: any(named: 'photos'),
      ),
    );
  });

  test('공유 실패는 그대로 Err', () async {
    when(() => dogs.getAll()).thenAnswer((_) async => const Ok([]));
    when(() => walks.watchAll()).thenAnswer((_) => Stream.value(const Ok([])));
    when(
      () => sharer.shareBytes(
        fileName: any(named: 'fileName'),
        bytes: any(named: 'bytes'),
        mimeType: any(named: 'mimeType'),
      ),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, isA<Err<void>>());
  });
}
