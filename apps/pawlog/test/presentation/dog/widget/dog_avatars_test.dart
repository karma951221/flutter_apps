import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/presentation/dog/widget/dog_avatars.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

import '../../../support/fakes.dart';
import '../../../support/pump_app.dart';

void main() {
  File photoFile(String path) => File(path);

  testWidgets('maxVisible 을 넘으면 나머지를 +N 으로 접는다', (tester) async {
    await pumpApp(
      tester,
      DogAvatars(
        dogs: [
          for (final id in ['a', 'b', 'c', 'd', 'e']) dog(id),
        ],
        photoFile: photoFile,
      ),
    );

    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('maxVisible 이하면 +N 이 없다', (tester) async {
    await pumpApp(
      tester,
      DogAvatars(
        dogs: [
          for (final id in ['a', 'b', 'c']) dog(id),
        ],
        photoFile: photoFile,
      ),
    );

    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('여러 마리는 12 씩 겹치고 바탕색 2 테두리로 떼어낸다', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: DogAvatars(dogs: [dog('a'), dog('b')], photoFile: photoFile),
      ),
    );

    // 지름 = 반지름 14 × 2 + 테두리 2 × 2 = 32, 두 번째는 32 - 12 = 20 만큼 민다.
    expect(tester.getSize(find.byType(DogAvatars)), const Size(52, 32));
    final ring =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(DogAvatars),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(ring.border, Border.all(color: PawlogColors.light.paper, width: 2));
  });
}
