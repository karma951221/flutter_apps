import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, AppBanner banner) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: banner),
    ),
  );

  Color backgroundOf(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(AppBanner),
          matching: find.byType(Material),
        ),
      )
      .color!;

  testWidgets('성격마다 바탕색과 기본 아이콘이 다르다', (tester) async {
    await pump(tester, const AppBanner(message: '안내'));
    final scheme = Theme.of(tester.element(find.text('안내'))).colorScheme;
    expect(backgroundOf(tester), scheme.secondaryContainer);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await pump(
      tester,
      const AppBanner(message: '주의', tone: AppBannerTone.warning),
    );
    expect(backgroundOf(tester), scheme.tertiaryContainer);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);

    await pump(
      tester,
      const AppBanner(message: '실패', tone: AppBannerTone.error),
    );
    expect(backgroundOf(tester), scheme.errorContainer);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('제목과 행동은 줬을 때만 그린다', (tester) async {
    var tapped = false;
    await pump(tester, const AppBanner(message: '본문'));
    expect(find.byType(TextButton), findsNothing);

    await pump(
      tester,
      AppBanner(
        title: '권한 필요',
        message: '본문',
        actionLabel: '허용',
        actionKey: const Key('allow'),
        onAction: () => tapped = true,
      ),
    );
    expect(find.text('권한 필요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('allow')));
    expect(tapped, isTrue);
  });
}
