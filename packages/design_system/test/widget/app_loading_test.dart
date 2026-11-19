import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('화면 가운데에 진행 표시 하나를 그린다', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLoading())),
    );

    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsOneWidget);
    expect(tester.getCenter(spinner), const Offset(200, 400));
  });

  testWidgets('delayed 면 잠깐은 빈칸이다가 그 뒤에 진행 표시를 그린다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLoading(delayed: true))),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(AppLoading.delay);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
