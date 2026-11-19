import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/common/status_label.dart';

void main() {
  testWidgets('성격마다 primary · onSurfaceVariant · error 로 칠한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusLabel('됨', tone: StatusTone.ok),
              StatusLabel('보통'),
              StatusLabel('필요', tone: StatusTone.attention),
            ],
          ),
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.text('됨'))).colorScheme;
    Color? colorOf(String t) => tester.widget<Text>(find.text(t)).style?.color;
    expect(colorOf('됨'), scheme.primary);
    expect(colorOf('보통'), scheme.onSurfaceVariant);
    expect(colorOf('필요'), scheme.error);
  });
}
