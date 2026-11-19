import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('고른 행에만 primary 색 체크를 그린다', (tester) async {
    var tapped = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              AppSelectTile(
                title: const Text('가'),
                selected: true,
                onTap: () => tapped = '가',
              ),
              AppSelectTile(
                title: const Text('나'),
                selected: false,
                onTap: () => tapped = '나',
              ),
            ],
          ),
        ),
      ),
    );

    final check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(find.byIcon(Icons.check), findsOneWidget);
    final context = tester.element(find.text('가'));
    expect(check.color, Theme.of(context).colorScheme.primary);

    await tester.tap(find.text('나'));
    expect(tapped, '나');
  });
}
