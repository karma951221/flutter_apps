import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawlog/domain/backup/entity/backup_data.dart';
import 'package:pawlog/domain/backup/entity/backup_import_result.dart';
import 'package:pawlog/domain/backup/policy/backup_codec.dart';
import 'package:pawlog/domain/backup/usecase/scenario/import_backup_scenario.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';

import '../../../../support/fakes.dart';
import '../../../../support/mock_backup.dart';

void main() {
  late MockDogRepository dogs;
  late MockWalkRepository walks;
  late MockPhotoStorage photos;
  late MockBackupArchiveCodec archive;
  late MockBackupFilePicker picker;
  late ImportBackupScenario scenario;

  // 저장소 안의 현재 행. findById 가 이것을 본다.
  late Map<String, Dog> storedDogs;
  late Map<String, Walk> storedWalks;

  final fileBytes = Uint8List.fromList([1, 2, 3]);

  final d1 = dog('d1', photoPath: 'dogs/d1.jpg');
  final d2 = dog('d2');
  WalkPhoto photo(String id) =>
      WalkPhoto(id: id, path: 'walks/$id.jpg', position: 0);
  final source = BackupData(
    exportedAt: t1,
    dogs: [d1, d2],
    walks: [
      BackupWalk(
        walk: walk(dogs: [d1], photos: [photo('p1')]),
        points: [trackPoint(37.5), trackPoint(37.6)],
      ),
      BackupWalk(
        walk: walk(dogs: [d2], photos: [photo('p2')]).copyWith(id: 'w2'),
        points: [trackPoint(37.7)],
      ),
      BackupWalk(
        walk: walk(dogs: [d1, d2]).copyWith(id: 'w3'),
        points: const [],
      ),
    ],
  );
  final json = BackupCodec.encode(source);
  final decoded = (BackupCodec.decode(json) as Ok<BackupData>).value;
  final zipPhotos = {
    'dogs/d1.jpg': Uint8List.fromList([10]),
    'walks/p1.jpg': Uint8List.fromList([11]),
    'walks/p2.jpg': Uint8List.fromList([12]),
    'unrelated.jpg': Uint8List.fromList([13]),
  };

  setUpAll(() {
    registerFallbacks();
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<WalkTrackPoint>[]);
  });

  setUp(() {
    dogs = MockDogRepository();
    walks = MockWalkRepository();
    photos = MockPhotoStorage();
    archive = MockBackupArchiveCodec();
    picker = MockBackupFilePicker();
    scenario = ImportBackupScenario(dogs, walks, photos, archive, picker);
    storedDogs = {};
    storedWalks = {};

    when(() => picker.pick()).thenAnswer((_) async => Ok(fileBytes));
    when(
      () => archive.unpack(fileBytes),
    ).thenReturn(Ok((json: json, photos: zipPhotos)));
    when(() => dogs.findById(any())).thenAnswer(
      (i) async => Ok(storedDogs[i.positionalArguments.first as String]),
    );
    when(() => walks.findById(any())).thenAnswer(
      (i) async => Ok(storedWalks[i.positionalArguments.first as String]),
    );
    when(() => dogs.upsert(any())).thenAnswer((i) async {
      final dog = i.positionalArguments.first as Dog;
      storedDogs[dog.id] = dog;
      return const Ok(null);
    });
    when(() => walks.insert(any(), any())).thenAnswer((i) async {
      final walk = i.positionalArguments.first as Walk;
      storedWalks[walk.id] = walk;
      return const Ok(null);
    });
    when(
      () => photos.write(any(), any()),
    ).thenAnswer((_) async => const Ok(null));
  });

  void verifyNoWrites() {
    verifyNever(() => dogs.upsert(any()));
    verifyNever(() => walks.insert(any(), any()));
    verifyNever(() => photos.write(any(), any()));
  }

  test('고르기를 취소하면 cancelled 이고 아무것도 읽지 않는다', () async {
    when(() => picker.pick()).thenAnswer((_) async => const Ok(null));

    final result = await scenario();

    expect(result, const BackupImportResult.cancelled());
    verifyNever(() => archive.unpack(any()));
    verifyNoWrites();
  });

  test('고르기가 실패하면 failed', () async {
    when(
      () => picker.pick(),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, const BackupImportResult.failed(Failure.unknown()));
    verifyNoWrites();
  });

  test('zip 을 풀지 못하면 invalid 이고 아무것도 쓰지 않는다', () async {
    when(
      () => archive.unpack(fileBytes),
    ).thenReturn(const Err(Failure.validation()));

    final result = await scenario();

    expect(result, const BackupImportResult.invalid());
    verifyNever(() => dogs.findById(any()));
    verifyNoWrites();
  });

  test('json 이 어긋나면(없는 반려견을 가리키는 산책) invalid 이고 아무것도 쓰지 않는다', () async {
    final broken = json.replaceFirst('"dogIds":["d2"]', '"dogIds":["ghost"]');
    expect(broken, isNot(json));
    when(
      () => archive.unpack(fileBytes),
    ).thenReturn(Ok((json: broken, photos: zipPhotos)));

    final result = await scenario();

    expect(result, const BackupImportResult.invalid());
    verifyNever(() => dogs.findById(any()));
    verifyNoWrites();
  });

  test('모두 새것이면 반려견 먼저 쓰고 imported(2, 3)', () async {
    final result = await scenario();

    expect(result, const BackupImportResult.imported(2, 3));
    verifyInOrder([
      () => dogs.upsert(decoded.dogs[0]),
      () => dogs.upsert(decoded.dogs[1]),
      () => walks.insert(decoded.walks[0].walk, decoded.walks[0].points),
      () => walks.insert(decoded.walks[1].walk, decoded.walks[1].points),
      () => walks.insert(decoded.walks[2].walk, decoded.walks[2].points),
    ]);
  });

  test('가져온 항목의 사진만 같은 상대 경로로 쓴다', () async {
    await scenario();

    verify(() => photos.write('dogs/d1.jpg', zipPhotos['dogs/d1.jpg']!));
    verify(() => photos.write('walks/p1.jpg', zipPhotos['walks/p1.jpg']!));
    verify(() => photos.write('walks/p2.jpg', zipPhotos['walks/p2.jpg']!));
    verifyNever(() => photos.write('unrelated.jpg', any()));
  });

  test('일부만 새것이면 새 항목과 그 사진만 쓴다', () async {
    storedDogs['d1'] = decoded.dogs[0];
    storedWalks['w1'] = decoded.walks[0].walk;

    final result = await scenario();

    expect(result, const BackupImportResult.imported(1, 2));
    verifyNever(() => dogs.upsert(decoded.dogs[0]));
    verify(() => dogs.upsert(decoded.dogs[1])).called(1);
    verifyNever(() => walks.insert(decoded.walks[0].walk, any()));
    verify(() => walks.insert(any(), any())).called(2);
    verifyNever(() => photos.write('dogs/d1.jpg', any()));
    verifyNever(() => photos.write('walks/p1.jpg', any()));
    verify(() => photos.write('walks/p2.jpg', any())).called(1);
  });

  test('같은 백업을 두 번 가져오면 두 번째는 아무것도 쓰지 않고 nothingNew', () async {
    final first = await scenario();
    expect(first, const BackupImportResult.imported(2, 3));
    clearInteractions(dogs);
    clearInteractions(walks);
    clearInteractions(photos);

    final second = await scenario();

    expect(second, const BackupImportResult.nothingNew());
    verifyNoWrites();
  });

  test('zip 에 없는 사진은 건너뛰고 항목은 가져온다', () async {
    when(
      () => archive.unpack(fileBytes),
    ).thenReturn(Ok((json: json, photos: <String, Uint8List>{})));

    final result = await scenario();

    expect(result, const BackupImportResult.imported(2, 3));
    verifyNever(() => photos.write(any(), any()));
  });

  test('존재 확인이 실패하면 아무것도 쓰지 않고 failed', () async {
    when(
      () => walks.findById('w2'),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, const BackupImportResult.failed(Failure.unknown()));
    verifyNoWrites();
  });

  test('반려견 쓰기가 실패하면 산책을 쓰지 않고 failed', () async {
    when(
      () => dogs.upsert(any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, const BackupImportResult.failed(Failure.unknown()));
    verifyNever(() => walks.insert(any(), any()));
    verifyNever(() => photos.write(any(), any()));
  });

  test('산책 쓰기가 실패하면 failed', () async {
    when(
      () => walks.insert(any(), any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, const BackupImportResult.failed(Failure.unknown()));
    verifyNever(() => photos.write(any(), any()));
  });

  test('사진 쓰기가 실패하면 failed', () async {
    when(
      () => photos.write(any(), any()),
    ).thenAnswer((_) async => const Err(Failure.unknown()));

    final result = await scenario();

    expect(result, const BackupImportResult.failed(Failure.unknown()));
  });
}
