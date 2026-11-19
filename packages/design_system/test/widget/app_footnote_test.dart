import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bodySmall · onSurfaceVariant 로 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppFootnote('도움말')),
      ),
    );
    final theme = Theme.of(tester.element(find.text('도움말')));
    final text = tester.widget<Text>(find.text('도움말'));
    expect(text.style?.fontSize, theme.textTheme.bodySmall?.fontSize);
    expect(text.style?.color, theme.colorScheme.onSurfaceVariant);
  });
}
