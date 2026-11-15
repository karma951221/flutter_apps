import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/diary/media/exif_photo_meta_reader.dart';
import 'package:walk/domain/diary/draft/photo_meta.dart';

/// 최소 JPEG(SOI · APP1 Exif · EOI). TIFF 는 little-endian, IFD0 → Exif IFD · GPS IFD.
Uint8List _exifJpeg({
  String? dateTimeOriginal,
  ({List<(int, int)> lat, String latRef, List<(int, int)> lng, String lngRef})?
  gps,
}) {
  // 엔트리: (태그, 타입, 개수, 값 바이트). 값이 4바이트를 넘으면 데이터 영역으로.
  const ascii = 2, long = 4, rational = 5;
  List<int> u16(int v) => [v & 0xff, (v >> 8) & 0xff];
  List<int> u32(int v) => [
    v & 0xff,
    (v >> 8) & 0xff,
    (v >> 16) & 0xff,
    (v >> 24) & 0xff,
  ];
  List<int> asciiBytes(String s) => [...s.codeUnits, 0];
  List<int> rationals(List<(int, int)> rs) => [
    for (final (n, d) in rs) ...[...u32(n), ...u32(d)],
  ];

  final exifEntries = <(int, int, int, List<int>)>[
    if (dateTimeOriginal != null)
      (
        0x9003,
        ascii,
        dateTimeOriginal.length + 1,
        asciiBytes(dateTimeOriginal),
      ),
  ];
  final gpsEntries = <(int, int, int, List<int>)>[
    if (gps != null) ...[
      (0x0001, ascii, 2, asciiBytes(gps.latRef)),
      (0x0002, rational, 3, rationals(gps.lat)),
      (0x0003, ascii, 2, asciiBytes(gps.lngRef)),
      (0x0004, rational, 3, rationals(gps.lng)),
    ],
  ];
  int ifdSize(int n) => 2 + n * 12 + 4;
  final hasExif = exifEntries.isNotEmpty;
  final hasGps = gpsEntries.isNotEmpty;
  final ifd0Count = (hasExif ? 1 : 0) + (hasGps ? 1 : 0);
  const ifd0At = 8;
  final exifAt = ifd0At + ifdSize(ifd0Count);
  final gpsAt = exifAt + (hasExif ? ifdSize(exifEntries.length) : 0);
  var dataAt = gpsAt + (hasGps ? ifdSize(gpsEntries.length) : 0);
  final data = <int>[];

  List<int> ifd(List<(int, int, int, List<int>)> entries) {
    final out = <int>[...u16(entries.length)];
    for (final (tag, type, count, value) in entries) {
      out
        ..addAll(u16(tag))
        ..addAll(u16(type))
        ..addAll(u32(count));
      if (value.length <= 4) {
        out.addAll([...value, ...List.filled(4 - value.length, 0)]);
      } else {
        out.addAll(u32(dataAt + data.length));
        data.addAll(value);
      }
    }
    return out..addAll(u32(0));
  }

  final ifd0 = ifd([
    if (hasExif) (0x8769, long, 1, u32(exifAt)),
    if (hasGps) (0x8825, long, 1, u32(gpsAt)),
  ]);
  final exifIfd = hasExif ? ifd(exifEntries) : <int>[];
  final gpsIfd = hasGps ? ifd(gpsEntries) : <int>[];
  final tiff = [
    ...'II'.codeUnits,
    ...u16(42),
    ...u32(ifd0At),
    ...ifd0,
    ...exifIfd,
    ...gpsIfd,
    ...data,
  ];
  final app1 = [...'Exif'.codeUnits, 0, 0, ...tiff];
  final length = app1.length + 2;
  return Uint8List.fromList([
    0xff, 0xd8, //
    0xff, 0xe1, (length >> 8) & 0xff, length & 0xff,
    ...app1,
    0xff, 0xd9,
  ]);
}

void main() {
  late Directory dir;
  const reader = ExifPhotoMetaReader();

  setUp(() => dir = Directory.systemTemp.createTempSync('exif_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> file(String name, List<int> bytes) async {
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  test('촬영 시각과 GPS 를 읽는다(남 · 서는 음수)', () async {
    final path = await file(
      'full.jpg',
      _exifJpeg(
        dateTimeOriginal: '2026:11:15 13:05:09',
        gps: (
          lat: [(37, 1), (32, 1), (2400, 100)],
          latRef: 'S',
          lng: [(127, 1), (3, 1), (0, 1)],
          lngRef: 'W',
        ),
      ),
    );

    final meta = await reader.read(path);

    expect(meta?.takenAt, DateTime(2026, 11, 15, 13, 5, 9));
    expect(meta?.lat, closeTo(-37.54, 1e-6));
    expect(meta?.lng, closeTo(-127.05, 1e-6));
  });

  test('시각만 있으면 좌표는 null', () async {
    final path = await file(
      'time.jpg',
      _exifJpeg(dateTimeOriginal: '2026:11:15 13:05:09'),
    );

    final meta = await reader.read(path);

    expect(meta, PhotoMeta(takenAt: DateTime(2026, 11, 15, 13, 5, 9)));
  });

  test('GPS 만 있으면 시각은 null(북 · 동은 양수)', () async {
    final path = await file(
      'gps.jpg',
      _exifJpeg(
        gps: (
          lat: [(37, 1), (30, 1), (0, 1)],
          latRef: 'N',
          lng: [(127, 1), (0, 1), (36, 1)],
          lngRef: 'E',
        ),
      ),
    );

    final meta = await reader.read(path);

    expect(meta?.takenAt, isNull);
    expect(meta?.lat, closeTo(37.5, 1e-6));
    expect(meta?.lng, closeTo(127.01, 1e-6));
  });

  test('EXIF 가 없으면 null', () async {
    final path = await file('none.jpg', [0xff, 0xd8, 0xff, 0xd9]);

    expect(await reader.read(path), isNull);
  });

  test('깨진 파일이면 null', () async {
    final path = await file('broken.jpg', List.generate(64, (i) => i * 7));

    expect(await reader.read(path), isNull);
  });

  test('없는 파일이면 null', () async {
    expect(await reader.read('${dir.path}/missing.jpg'), isNull);
  });

  test('모양이 어긋난 시각 글은 시각만 null', () async {
    final path = await file(
      'bad-time.jpg',
      _exifJpeg(
        dateTimeOriginal: '0000:00:00 00:00:00',
        gps: (
          lat: [(37, 1), (30, 1), (0, 1)],
          latRef: 'N',
          lng: [(127, 1), (0, 1), (0, 1)],
          lngRef: 'E',
        ),
      ),
    );

    final meta = await reader.read(path);

    expect(meta?.takenAt, isNull);
    expect(meta?.lat, closeTo(37.5, 1e-6));
  });
}
