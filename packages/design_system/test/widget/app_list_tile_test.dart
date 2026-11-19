import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('탭과 길게 누르기를 따로 받는다', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppListTile(
            title: const Text('행'),
            onTap: () => calls.add('tap'),
            onLongPress: () => calls.add('long'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('행'));
    await tester.longPress(find.text('행'));
    expect(calls, ['tap', 'long']);
  });
}
