import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/presentation/theme/pawlog_theme.dart';

/// WCAG 대비 비율.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('PawlogTheme', () {
    test('라이트는 회백지 바탕에 리드줄 남색이 주 색이다', () {
      final theme = PawlogTheme.light();
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF2C3B57));
      expect(theme.colorScheme.surface, const Color(0xFFF4F3EF));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F3EF));
      expect(theme.colorScheme.error, const Color(0xFFB3402E));
    });

    test('다크는 먹색 바탕에 남색을 밝게 올리고 연두는 그대로 둔다', () {
      final theme = PawlogTheme.dark();
      final colors = theme.extension<PawlogColors>()!;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFA9B8D6));
      expect(theme.colorScheme.surface, const Color(0xFF1B1C19));
      expect(colors.sheet, const Color(0xFF23241F));
      expect(colors.accent, PawlogColors.light.accent);
    });

    test('연두는 ColorScheme 어디에도 들어가지 않는다 — 버튼 · 배경 · 텍스트 금지', () {
      for (final theme in [PawlogTheme.light(), PawlogTheme.dark()]) {
        final accent = theme.extension<PawlogColors>()!.accent;
        final scheme = theme.colorScheme;
        expect([
          scheme.primary,
          scheme.secondary,
          scheme.tertiary,
          scheme.surface,
          scheme.onSurface,
          scheme.primaryContainer,
          scheme.secondaryContainer,
        ], isNot(contains(accent)));
      }
    });

    test('입력칸 테두리는 구분선보다 진하고 바탕과 3:1 이상 벌어진다(QA P4)', () {
      for (final theme in [PawlogTheme.light(), PawlogTheme.dark()]) {
        final colors = theme.extension<PawlogColors>()!;
        final border =
            theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
        expect(border.borderSide.color, colors.inputBorder);
        expect(border.borderSide.color, isNot(colors.rule));
        expect(_contrast(colors.inputBorder, colors.paper), greaterThan(3));
        expect(_contrast(colors.inputBorder, colors.sheet), greaterThan(3));
      }
    });

    test('제목은 고운돋움, 본문 · 숫자는 Pretendard, 메모는 개구다', () {
      final theme = PawlogTheme.light();
      final styles = theme.extension<PawlogTextStyles>()!;
      expect(theme.textTheme.titleLarge!.fontFamily, PawlogFonts.heading);
      expect(theme.textTheme.headlineMedium!.fontFamily, PawlogFonts.heading);
      expect(theme.textTheme.headlineMedium!.fontSize, 26);
      expect(theme.textTheme.bodyLarge!.fontFamily, PawlogFonts.body);
      expect(theme.textTheme.bodyLarge!.fontSize, 15);
      expect(theme.textTheme.labelMedium!.fontSize, 12);
      expect(theme.appBarTheme.titleTextStyle!.fontFamily, PawlogFonts.heading);
      expect(styles.memo.fontFamily, PawlogFonts.memo);
      expect(styles.memo.fontSize, 20);
      expect(styles.dogName.fontFamily, PawlogFonts.heading);
    });

    test('숫자는 Pretendard 700 + 타뷸러이고 히어로는 본문의 세 배 가까이다', () {
      final styles = PawlogTheme.light().extension<PawlogTextStyles>()!;
      for (final style in [styles.numberHero, styles.number, styles.feedDay]) {
        expect(style.fontFamily, PawlogFonts.body);
        expect(style.fontWeight, FontWeight.w700);
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
      expect(styles.numberHero.fontSize, 44);
      expect(styles.number.fontSize, 20);
      expect(styles.feedDay.fontSize, 30);
    });

    test('모서리는 역할마다 다르다 — 사진 4 · 입력 12 · 시트 20 · 버튼 알약', () {
      final theme = PawlogTheme.light();
      expect(PawlogRadius.photo, 4);
      expect(PawlogRadius.control, 12);
      expect(PawlogRadius.sheet, 20);
      final input = theme.inputDecorationTheme.border! as OutlineInputBorder;
      expect(input.borderRadius, PawlogRadius.controlAll);
      expect(
        theme.filledButtonTheme.style!.shape!.resolve({}),
        isA<StadiumBorder>(),
      );
      expect(
        theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        PawlogSize.primaryButton,
      );
      final sheet = theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
      expect(sheet.borderRadius, PawlogRadius.sheetTop);
    });

    test('칩은 체크 표시 없이 바탕 · 테두리로 선택을 보인다(QA P2)', () {
      final theme = PawlogTheme.light();
      final colors = theme.extension<PawlogColors>()!;
      expect(theme.chipTheme.showCheckmark, isFalse);
      expect(
        theme.chipTheme.color!.resolve({WidgetState.selected}),
        colors.primary,
      );
      expect(theme.chipTheme.color!.resolve({}), colors.sheet);
    });

    test('간격 토큰은 design.md 의 4 · 8 · 14 · 20 · 28 · 48 이다', () {
      expect(
        [
          PawlogSpacing.xs,
          PawlogSpacing.sm,
          PawlogSpacing.md,
          PawlogSpacing.lg,
          PawlogSpacing.xl,
          PawlogSpacing.xxl,
        ],
        [4, 8, 14, 20, 28, 48],
      );
    });

    testWidgets('확장이 없는 테마에서도 밝기에 맞는 색을 돌려준다', (tester) async {
      late PawlogColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              colors = PawlogColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(colors, same(PawlogColors.dark));
    });
  });

  group('PawlogMotion.off', () {
    testWidgets('애니메이션 줄이기가 켜지면 참이다', (tester) async {
      late bool off;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              off = PawlogMotion.off(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(off, isTrue);
    });
  });
}
