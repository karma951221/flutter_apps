import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/alarm/widget/ringing_ripple.dart';

Widget _app({bool off = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: off),
  child: const MaterialApp(
    home: Scaffold(body: RingingRipple(child: Icon(Icons.alarm))),
  ),
);

Finder get _painter => find.descendant(
  of: find.byType(RingingRipple),
  matching: find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter != null,
  ),
);

double _phase(WidgetTester tester) =>
    (tester.widget<CustomPaint>(_painter).painter! as dynamic).phase as double;

void main() {
  testWidgets('켜면 위상이 계속 변한다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 600));
    final a = _phase(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final b = _phase(tester);

    expect(b, isNot(a));
    expect(find.byIcon(Icons.alarm), findsOneWidget);
  });

  testWidgets('애니메이션 제거면 돌지 않는다', (tester) async {
    await tester.pumpWidget(_app(off: true));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byIcon(Icons.alarm), findsOneWidget);
  });
}
