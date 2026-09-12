import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('메시지만 있으면 메시지만 그린다', (tester) async {
    await pump(tester, const AppPlaceholder(message: '불러오지 못했습니다'));

    expect(find.text('불러오지 못했습니다'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('아이콘은 넘겼을 때만 그린다', (tester) async {
    await pump(
      tester,
      const AppPlaceholder(message: '비어 있습니다', icon: Icons.edit_note_outlined),
    );

    expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
  });

  testWidgets('보조 설명은 넘겼을 때만 그린다', (tester) async {
    await pump(
      tester,
      const AppPlaceholder(message: '비어 있습니다', description: '첫 글을 남겨보세요.'),
    );

    expect(find.text('첫 글을 남겨보세요.'), findsOneWidget);
  });

  testWidgets('행동 버튼은 라벨과 콜백이 둘 다 있어야 그린다', (tester) async {
    await pump(
      tester,
      const AppPlaceholder(message: '실패', actionLabel: '다시 시도'),
    );
    expect(find.text('다시 시도'), findsNothing);

    var tapped = 0;
    await pump(
      tester,
      AppPlaceholder(
        message: '실패',
        actionLabel: '다시 시도',
        onAction: () => tapped++,
      ),
    );
    await tester.tap(find.text('다시 시도'));
    expect(tapped, 1);
  });
}
