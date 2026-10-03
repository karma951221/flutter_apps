import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/theme/walk_motion.dart';
import 'package:walk/presentation/walk/widget/step_goal_ring.dart';

Future<void> _pump(WidgetTester tester, double ratio, {bool off = false}) =>
    tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: off),
        child: MaterialApp(
          home: Center(
            child: StepGoalRing(ratio: ratio, child: const SizedBox()),
          ),
        ),
      ),
    );

double _progress(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(StepGoalRing),
      matching: find.byType(CustomPaint),
    ),
  );
  return (paint.painter! as StepGoalRingPainter).progress;
}

void main() {
  testWidgets('진입 때 0 에서 비율까지, 바뀌면 직전 값에서 새 값까지', (tester) async {
    await _pump(tester, 0.5);
    expect(_progress(tester), 0);

    await tester.pump(WalkMotion.long ~/ 2);
    expect(_progress(tester), greaterThan(0));
    expect(_progress(tester), lessThan(0.5));

    await tester.pumpAndSettle();
    expect(_progress(tester), 0.5);

    await _pump(tester, 0.8);
    expect(_progress(tester), closeTo(0.5, 0.01));
    await tester.pumpAndSettle();
    expect(_progress(tester), closeTo(0.8, 1e-9));
  });

  testWidgets('넘친 비율은 1 에서 멈춘다', (tester) async {
    await _pump(tester, 1.25, off: true);
    await tester.pump();
    expect(_progress(tester), 1);
  });

  testWidgets('애니메이션 끄기면 첫 프레임부터 끝 값', (tester) async {
    await _pump(tester, 0.6, off: true);
    await tester.pump();
    expect(_progress(tester), closeTo(0.6, 1e-9));
  });
}
