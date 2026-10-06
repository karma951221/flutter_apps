import 'dart:async';
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

  group('fadeInImage', () {
    Future<void> pumpFading(
      WidgetTester tester,
      Widget avatar, {
      bool disableAnimations = false,
    }) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: Center(child: avatar)),
        ),
      ),
    );

    Finder inAvatar(Type type) => find.descendant(
      of: find.byType(AppAvatar),
      matching: find.byType(type),
    );

    testWidgets('기본값이면 CircleAvatar.foregroundImage 경로 그대로다', (tester) async {
      await pump(tester, AppAvatar(nickname: '몽이', imageBytes: _png));

      expect(foreground(tester), isA<MemoryImage>());
      expect(inAvatar(Image), findsNothing);
      expect(inAvatar(AnimatedOpacity), findsNothing);
    });

    testWidgets('켜면 이니셜 위에서 투명하게 시작해 로드되면 보인다', (tester) async {
      // 새 바이트여야 앞선 테스트가 채운 이미지 캐시에 걸리지 않는다.
      await pumpFading(
        tester,
        AppAvatar(
          nickname: '몽이',
          imageBytes: Uint8List.fromList(_png),
          fadeInImage: true,
        ),
      );

      expect(find.text('몽'), findsOneWidget);
      expect(foreground(tester), isNull);
      AnimatedOpacity opacity() =>
          tester.widget<AnimatedOpacity>(inAvatar(AnimatedOpacity));
      expect(opacity().opacity, 0);

      // 디코딩은 실제 비동기 작업이라 가짜 시계 밖에서 끝낸다.
      await tester.runAsync(() async {
        final image = tester.widget<Image>(inAvatar(Image)).image;
        final completer = Completer<void>();
        image
            .resolve(ImageConfiguration.empty)
            .addListener(ImageStreamListener((_, _) => completer.complete()));
        await completer.future;
      });
      await tester.pump();
      expect(opacity().opacity, 1);

      await tester.pumpAndSettle();
      expect(find.text('몽'), findsOneWidget);
      expect(opacity().opacity, 1);
    });

    testWidgets('캐시에 있어 동기로 그려지면 페이드 없이 바로 그린다', (tester) async {
      final provider = MemoryImage(_png);
      await pumpFading(tester, const SizedBox());
      await tester.runAsync(
        () => precacheImage(provider, tester.element(find.byType(SizedBox))),
      );

      await pumpFading(
        tester,
        AppAvatar(nickname: '몽이', imageBytes: _png, fadeInImage: true),
      );

      expect(inAvatar(Image), findsOneWidget);
      expect(inAvatar(AnimatedOpacity), findsNothing);
    });

    testWidgets('이미지가 없으면 켜도 이니셜만 그린다', (tester) async {
      await pumpFading(
        tester,
        const AppAvatar(nickname: '몽이', fadeInImage: true),
      );

      expect(find.text('몽'), findsOneWidget);
      expect(inAvatar(Image), findsNothing);
      expect(inAvatar(AnimatedOpacity), findsNothing);
    });

    testWidgets('불러오지 못하면 이니셜을 그대로 둔다', (tester) async {
      await pumpFading(
        tester,
        const AppAvatar(
          nickname: '몽이',
          imageUrl: 'https://x/y.png',
          fadeInImage: true,
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(find.text('몽'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('애니메이션 줄이기면 켜도 기존 경로 그대로다', (tester) async {
      await pumpFading(
        tester,
        AppAvatar(nickname: '몽이', imageBytes: _png, fadeInImage: true),
        disableAnimations: true,
      );

      expect(foreground(tester), isA<MemoryImage>());
      expect(inAvatar(Image), findsNothing);
      expect(inAvatar(AnimatedOpacity), findsNothing);
    });
  });
}
