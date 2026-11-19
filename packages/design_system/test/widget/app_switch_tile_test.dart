import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<bool>> pump(WidgetTester tester, {bool enabled = true}) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSwitchTile(
            title: const Text('진동'),
            subtitle: const Text('알람이 울릴 때'),
            value: false,
            switchKey: const Key('vibrate'),
            onChanged: enabled ? changes.add : null,
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('글자를 눌러도 스위치를 눌러도 바뀐다', (tester) async {
    final changes = await pump(tester);
    await tester.tap(find.text('진동'));
    await tester.tap(find.byKey(const Key('vibrate')));
    expect(changes, [true, true]);
  });

  testWidgets('onChanged 가 없으면 행 전체가 꺼진다', (tester) async {
    await pump(tester, enabled: false);
    expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });
}
