import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/diary/media/media_store.dart';
import 'package:walk/presentation/diary/widget/entry_media_view.dart';
import 'package:walk/presentation/theme/walk_theme.dart';

import '../../../support/diary_fixtures.dart';

class _MockStore extends Mock implements MediaStore {}

void main() {
  setUp(() {
    final store = _MockStore();
    when(
      () => store.resolve(any()),
    ).thenAnswer((inv) => File('/fake/${inv.positionalArguments.single}'));
    getIt.registerSingleton<MediaStore>(store);
  });

  tearDown(getIt.reset);

  for (final (name, theme) in [
    ('밝은 테마', WalkTheme.light()),
    ('어두운 테마', WalkTheme.dark()),
  ]) {
    testWidgets('$name: 영상 표시는 어두운 원 위의 밝은 ▶ 라 어떤 썸네일 위에서도 보인다', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: SizedBox(
            width: 300,
            height: 300,
            child: EntryMediaView(media: videoMedia('v1')),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.play_arrow_rounded));
      expect(icon.color!.computeLuminance(), greaterThan(0.7));
      final badge = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byIcon(Icons.play_arrow_rounded),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = badge.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color!.computeLuminance(), lessThan(0.1));
      expect(decoration.color!.a, greaterThan(0.3));
    });
  }
}
