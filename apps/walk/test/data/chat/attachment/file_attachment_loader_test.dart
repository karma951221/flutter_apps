import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/chat/attachment/file_attachment_loader.dart';
import 'package:walk/domain/chat/attachment/attachment_loader.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/attachment/chat_attachment.dart';

void main() {
  late Directory dir;

  /// 압축기가 받은 경로. 줄인 결과는 [jpeg].
  late List<String> compressed;
  final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);

  late FileAttachmentLoader loader;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('attachment_loader_test');
    compressed = [];
    loader = FileAttachmentLoader.withCompressor((path) async {
      compressed.add(path);
      return jpeg;
    });
  });

  tearDown(() => dir.delete(recursive: true));

  Future<PickedFile> write(
    String name,
    List<int> bytes, {
    String? workspacePath,
  }) async {
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return PickedFile(
      name: name,
      path: file.path,
      sizeBytes: bytes.length,
      workspacePath: workspacePath,
    );
  }

  test('작은 png 는 줄인 JPEG 사진 첨부', () async {
    final file = await write('a.png', [1, 2, 3]);

    final load = await loader.load(file);

    expect(load, isA<AttachmentLoaded>());
    final image = (load as AttachmentLoaded).attachment as ImageAttachment;
    expect(image.name, 'a.png');
    expect(image.mediaType, 'image/jpeg');
    expect(image.bytes, jpeg);
    expect(compressed, [file.path]);
  });

  test('줄이지 못한 사진은 unsupportedType', () async {
    loader = FileAttachmentLoader.withCompressor((_) async => null);
    final file = await write('a.jpg', [1]);

    expect(
      await loader.load(file),
      const AttachmentLoad.rejected(
        'a.jpg',
        AttachmentRejection.unsupportedType,
      ),
    );
  });

  test('사진 줄이기가 Error 를 던져도 unsupportedType', () async {
    loader = FileAttachmentLoader.withCompressor(
      (_) async => throw StateError('plugin'),
    );
    final file = await write('a.heic', [1]);

    expect(
      await loader.load(file),
      const AttachmentLoad.rejected(
        'a.heic',
        AttachmentRejection.unsupportedType,
      ),
    );
  });

  test('readOriginal 은 원본 바이트 그대로', () async {
    final file = await write('a.png', [7, 8, 9]);

    expect(await loader.readOriginal(file.path), [7, 8, 9]);
  });

  test('pdf 는 바이트 그대로, workspacePath 를 옮긴다', () async {
    final file = await write('b.PDF', [
      37,
      80,
      68,
      70,
    ], workspacePath: 'inbox/b.PDF');

    final load = await loader.load(file) as AttachmentLoaded;

    final pdf = load.attachment as PdfAttachment;
    expect(pdf.bytes, [37, 80, 68, 70]);
    expect(pdf.workspacePath, 'inbox/b.PDF');
  });

  test('10MB+1 pdf 는 tooLarge', () async {
    final file = await write(
      'big.pdf',
      Uint8List(AttachmentRules.maxPdfBytes + 1),
    );

    expect(
      await loader.load(file),
      const AttachmentLoad.rejected('big.pdf', AttachmentRejection.tooLarge),
    );
  });

  test('알려 준 크기가 작아도 실제 파일이 크면 tooLarge', () async {
    final real = await write(
      't.txt',
      Uint8List(AttachmentRules.maxTextBytes + 1),
    );
    final lying = PickedFile(name: real.name, path: real.path, sizeBytes: 1);

    expect(
      await loader.load(lying),
      const AttachmentLoad.rejected('t.txt', AttachmentRejection.tooLarge),
    );
  });

  test('UTF-8 텍스트는 글로 읽는다', () async {
    final file = await write('note.md', utf8.encode('# 안녕'));

    final load = await loader.load(file) as AttachmentLoaded;

    expect((load.attachment as TextAttachment).text, '# 안녕');
  });

  // dart:convert 의 utf8.decode 가 맨 앞 BOM 을 뗀다 — 그 동작을 고정해 둔다.
  test('맨 앞 UTF-8 BOM 은 떼고 읽는다(가운데 것은 그대로)', () async {
    final file = await write('bom.csv', [
      0xef,
      0xbb,
      0xbf,
      ...utf8.encode('a,b﻿'),
    ]);

    final load = await loader.load(file) as AttachmentLoaded;

    expect((load.attachment as TextAttachment).text, 'a,b﻿');
  });

  test('0xff 0xfe 바이트 .txt 는 notUtf8', () async {
    final file = await write('bad.txt', [0xff, 0xfe, 0x41, 0x00]);

    expect(
      await loader.load(file),
      const AttachmentLoad.rejected('bad.txt', AttachmentRejection.notUtf8),
    );
  });

  test('.docx 는 unsupportedType — 줄이지도 읽지도 않는다', () async {
    final file = await write('doc.docx', [1, 2]);

    expect(
      await loader.load(file),
      const AttachmentLoad.rejected(
        'doc.docx',
        AttachmentRejection.unsupportedType,
      ),
    );
    expect(compressed, isEmpty);
  });

  test('파일을 읽지 못하면 unsupportedType', () async {
    const file = PickedFile(
      name: 'gone.txt',
      path: '/nope/gone.txt',
      sizeBytes: 3,
    );

    expect(
      await loader.load(file),
      const AttachmentLoad.rejected(
        'gone.txt',
        AttachmentRejection.unsupportedType,
      ),
    );
  });
}
