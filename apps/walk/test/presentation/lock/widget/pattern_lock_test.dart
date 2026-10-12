import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l10n/l10n.dart';
import 'package:walk/presentation/lock/widget/pattern_lock.dart';

void main() {
  late List<List<int>> completed;

  setUp(() => completed = []);

  Future<void> pump(WidgetTester tester, {bool enabled = true}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: PatternLock(
                  onCompleted: completed.add,
                  enabled: enabled,
                ),
              ),
            ),
          ),
        ),
      );

  /// 격자 점 [index] 의 화면 좌표.
  Offset dot(WidgetTester tester, int index) {
    final grid = find.byKey(PatternLock.gridKey);
    final origin = tester.getTopLeft(grid);
    final cell = tester.getSize(grid).width / 3;
    return origin + Offset((index % 3 + 0.5) * cell, (index ~/ 3 + 0.5) * cell);
  }

  /// 점에서 점으로 곧장 건너뛰며 그린다(사이의 점을 지나지 않는다).
  Future<void> draw(WidgetTester tester, List<int> dots) async {
    final gesture = await tester.startGesture(dot(tester, dots.first));
    await tester.pump();
    for (final d in dots.skip(1)) {
      await gesture.moveTo(dot(tester, d));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
  }

  testWidgets('0→1→2→5 → [0,1,2,5]', (tester) async {
    await pump(tester);

    await draw(tester, [0, 1, 2, 5]);

    expect(completed, [
      [0, 1, 2, 5],
    ]);
  });

  testWidgets('0→2 는 건너뛴 1 을 넣는다', (tester) async {
    await pump(tester);

    await draw(tester, [0, 2, 5, 8]);

    expect(completed, [
      [0, 1, 2, 5, 8],
    ]);
  });

  testWidgets('같은 점을 다시 지나도 한 번만', (tester) async {
    await pump(tester);

    await draw(tester, [0, 1, 0, 4, 1, 8]);

    expect(completed, [
      [0, 1, 4, 8],
    ]);
  });

  testWidgets('건너뛴 점이 이미 쓰였으면 다시 넣지 않는다', (tester) async {
    await pump(tester);

    await draw(tester, [1, 0, 2, 5]);

    expect(completed, [
      [1, 0, 2, 5],
    ]);
  });

  testWidgets('3점이면 onCompleted 없이 오류 문구', (tester) async {
    await pump(tester);

    await draw(tester, [0, 1, 2]);

    expect(completed, isEmpty);
    expect(find.text('점을 4개 이상 이어 주세요'), findsOneWidget);

    await draw(tester, [0, 1, 2, 5]);
    expect(find.text('점을 4개 이상 이어 주세요'), findsNothing);
    expect(completed, hasLength(1));
  });

  testWidgets('enabled false 면 그려도 무시', (tester) async {
    await pump(tester, enabled: false);

    await draw(tester, [0, 1, 2, 5]);

    expect(completed, isEmpty);
  });
}
