import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/presentation/dog/widget/dog_chips.dart';

import '../../../support/fakes.dart';
import '../../../support/pump_app.dart';

void main() {
  testWidgets('선택은 체크 표시 없이 칩 상태로만 보인다(QA P2)', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: DogChips(
          dogs: [dog('a'), dog('b')],
          selectedIds: const {'a'},
          onToggle: (_) {},
        ),
      ),
    );

    FilterChip chip(String id) =>
        tester.widget(find.byKey(Key('walk-active-dog-chip-$id')));
    expect(chip('a').selected, isTrue);
    expect(chip('b').selected, isFalse);
    expect(chip('a').showCheckmark, isFalse);
    expect(find.byIcon(Icons.check), findsNothing);
  });
}
