import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';

// 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  Future<void> pump(WidgetTester tester, AppAvatar avatar) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: avatar)),
    ),
  );

  ImageProvider<Object>? foreground(WidgetTester tester) =>
      tester.widget<CircleAvatar>(find.byType(CircleAvatar)).foregroundImage;

  testWidgets('imageFile 이 있으면 FileImage 를 쓴다', (tester) async {
    final file = File('${Directory.systemTemp.path}/avatar_test.png')
      ..writeAsBytesSync(_png);

    await pump(
      tester,
      AppAvatar(nickname: '몽이', imageFile: file, imageUrl: 'https://x/y.png'),
    );

    final image = foreground(tester);
    expect(image, isA<FileImage>());
    expect((image! as FileImage).file.path, file.path);
  });

  testWidgets('imageBytes 는 imageFile 보다 우선한다', (tester) async {
    await pump(
      tester,
      AppAvatar(
        nickname: '몽이',
        imageBytes: Uint8List.fromList(_png),
        imageFile: File('${Directory.systemTemp.path}/avatar_test.png'),
      ),
    );

    expect(foreground(tester), isA<MemoryImage>());
  });

  testWidgets('imageFile 이 없으면 imageUrl 을 쓴다', (tester) async {
    await pump(
      tester,
      const AppAvatar(nickname: '몽이', imageUrl: 'https://x/y.png'),
    );

    expect(foreground(tester), isA<NetworkImage>());
    tester.takeException(); // 테스트 환경은 네트워크가 막혀 있다.
  });
}
