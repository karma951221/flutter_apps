import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/theme/walk_motion.dart';
import 'package:walk/presentation/theme/walk_theme.dart';

void main() {
  test('walk 테마는 초록 시드다', () {
    expect(
      WalkTheme.light().colorScheme.primary,
      ColorScheme.fromSeed(seedColor: WalkTheme.seed).primary,
    );
  });

  testWidgets('애니메이션 끄기를 읽는다', (tester) async {
    late bool off;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            off = WalkMotion.off(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(off, isTrue);
  });
}
