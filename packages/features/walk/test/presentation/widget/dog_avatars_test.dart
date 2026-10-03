import 'dart:io';

import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/pump_app.dart';

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
}
