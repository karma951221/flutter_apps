import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('titleSmall · primary 색으로 머리를 그리고 머리로 읽힌다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppSectionHeader('알림')),
      ),
    );

    final context = tester.element(find.text('알림'));
    final theme = Theme.of(context);
    final text = tester.widget<Text>(find.text('알림'));
    expect(text.style?.fontSize, theme.textTheme.titleSmall?.fontSize);
    expect(text.style?.color, theme.colorScheme.primary);
    expect(
      tester.getSemantics(find.text('알림')),
      matchesSemantics(label: '알림', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('trailing 을 머리 줄 오른쪽에 둔다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppSectionHeader('목록', trailing: Text('모두'))),
      ),
    );
    expect(
      tester.getCenter(find.text('모두')).dx,
      greaterThan(tester.getCenter(find.text('목록')).dx),
    );
  });
}
