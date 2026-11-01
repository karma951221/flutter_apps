import 'dart:convert';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/presentation/chat/widget/chat_vendor_icon.dart';

const _logoPath = 'assets/chat/vendors/anthropic.svg';
const _svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>';

/// 테스트가 고른 자산만 돌려주는 번들. 없는 키는 읽기 실패.
///
/// 실패는 동기로 던진다. flutter_svg 2.3 의 `Cache.putIfAbsent` 가 실패한 future 에
/// 오류 처리기를 달지 않아, 비동기 실패는 errorBuilder 와 별개로 잡히지 않은 오류로도
/// 올라와 테스트를 깨뜨린다(위젯이 고칠 수 없는 패키지 쪽 문제).
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) {
    final value = assets[key];
    if (value == null) throw FlutterError('없는 자산: $key');
    return Future.value(
      ByteData.sublistView(Uint8List.fromList(utf8.encode(value))),
    );
  }
}

void main() {
  // flutter_svg 의 바이트 캐시는 전역이다. 테스트끼리 같은 경로를 쓰므로 비운다.
  setUp(svg.cache.clear);

  Future<void> pump(WidgetTester tester, Widget child, {AssetBundle? bundle}) {
    Widget body = Center(child: child);
    if (bundle != null) body = DefaultAssetBundle(bundle: bundle, child: body);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: body),
      ),
    );
  }

  testWidgets('확인된 로고가 없으면 모노그램 C 를 그리고 SvgPicture 가 없다', (tester) async {
    await pump(tester, const ChatVendorIcon(ChatVendor.anthropic, size: 24));

    expect(ChatVendorIcon.confirmedLogos, isEmpty);
    expect(find.text('C'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets('size 를 주지 않으면 IconTheme 크기', (tester) async {
    await pump(
      tester,
      const IconTheme(
        data: IconThemeData(size: 32),
        child: ChatVendorIcon(ChatVendor.anthropic),
      ),
    );

    expect(tester.getSize(find.byType(ChatVendorIcon)), const Size(32, 32));
  });

  testWidgets('로고가 있으면 SvgPicture 를 그 경로로 그린다', (tester) async {
    await pump(
      tester,
      const ChatVendorIcon(
        ChatVendor.anthropic,
        size: 24,
        logos: {ChatVendor.anthropic: ChatVendorLogo(_logoPath)},
      ),
      bundle: _FakeBundle({_logoPath: _svg}),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect((svg.bytesLoader as SvgAssetLoader).assetName, _logoPath);
    expect(svg.colorFilter, isNull);
  });

  testWidgets('자산을 읽지 못하면 모노그램으로', (tester) async {
    await pump(
      tester,
      const ChatVendorIcon(
        ChatVendor.anthropic,
        size: 24,
        logos: {ChatVendor.anthropic: ChatVendorLogo(_logoPath)},
      ),
      bundle: _FakeBundle({}),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('C'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('tintable 이면 onSurface 로 칠한다', (tester) async {
    await pump(
      tester,
      const ChatVendorIcon(
        ChatVendor.anthropic,
        size: 24,
        logos: {
          ChatVendor.anthropic: ChatVendorLogo(_logoPath, tintable: true),
        },
      ),
      bundle: _FakeBundle({_logoPath: _svg}),
    );

    final scheme = Theme.of(
      tester.element(find.byType(ChatVendorIcon)),
    ).colorScheme;
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      svg.colorFilter,
      ColorFilter.mode(scheme.onSurface, BlendMode.srcIn),
    );
  });

  testWidgets('시맨틱 라벨은 벤더 이름', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const ChatVendorIcon(ChatVendor.anthropic, size: 24));

    expect(find.bySemanticsLabel('Claude'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('chatVendorName · chatVendorCompany', (tester) async {
    await pump(tester, const SizedBox());
    final l10n = AppLocalizations.of(tester.element(find.byType(SizedBox)));

    expect(chatVendorName(l10n, ChatVendor.anthropic), 'Claude');
    expect(chatVendorName(l10n, ChatVendor.openai), 'GPT');
    expect(chatVendorCompany(l10n, ChatVendor.anthropic), 'Anthropic');
    expect(chatVendorCompany(l10n, ChatVendor.openai), 'OpenAI');
  });
}
