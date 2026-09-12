import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 상대 휘도.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// 두 색의 대비비 (1.0 ~ 21.0).
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final light = AppTheme.light().colorScheme;
  final dark = AppTheme.dark().colorScheme;

  // 본문·라벨은 전부 colorScheme 파생색이다. Material 3 의 on/surface 짝이
  // 두 테마에서 실제로 AA(4.5:1)를 넘는지 확인한다 — 시드만 바꿔도 깨질 수 있다.
  group('colorScheme 파생색은 두 테마 모두에서 본문 대비를 만족한다', () {
    for (final (name, scheme) in [('light', light), ('dark', dark)]) {
      test('$name — onSurface / surface', () {
        expect(contrast(scheme.onSurface, scheme.surface), greaterThan(4.5));
      });

      test('$name — onSurfaceVariant / surface (보조 문구)', () {
        expect(
          contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThan(4.5),
        );
      });

      test('$name — onPrimary / primary (기본 버튼)', () {
        expect(contrast(scheme.onPrimary, scheme.primary), greaterThan(4.5));
      });

      test('$name — onErrorContainer / errorContainer (오류 스낵바)', () {
        expect(
          contrast(scheme.onErrorContainer, scheme.errorContainer),
          greaterThan(4.5),
        );
      });

      test('$name — onPrimaryContainer / primaryContainer (성공 스낵바)', () {
        expect(
          contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThan(4.5),
        );
      });

      test('$name — error / surface (destructive 라벨)', () {
        // AppConfirmDialog 의 확인 버튼과 AppOverflowMenu 의 destructive 항목이
        // 표면 위에 error 색 글자를 그린다.
        expect(contrast(scheme.error, scheme.surface), greaterThan(4.5));
      });
    }
  });

  // AppColors.like · dislike 는 지금 lib · test 어디에서도 쓰이지 않는다
  // (features/preferences/history.md 의 "부수 발견"). 죽은 토큰이라 지금은 대비
  // 문제가 없지만, 되살려 쓸 때를 대비해 실측값을 고정해 둔다.
  //
  // 2026-08-27 측정 — history.md 는 "like 가 **다크**에서 AA 에 걸린다(~3.5:1)"고
  // 적었지만 실제로는 반대다. 그 ~3.5 는 **라이트** 표면 값이었다.
  //
  //           라이트   다크
  //   like     3.28    5.38
  //   dislike  4.29    4.11
  group('브랜드 고정색 — 되살린다면 작은 글자에는 쓸 수 없다', () {
    test('like 는 라이트에서 AA 미만, 다크에서는 통과한다', () {
      expect(contrast(AppColors.like, light.surface), lessThan(4.5));
      expect(contrast(AppColors.like, dark.surface), greaterThan(4.5));
    });

    test('dislike 는 양쪽 테마 모두 AA 미만이다', () {
      expect(contrast(AppColors.dislike, light.surface), lessThan(4.5));
      expect(contrast(AppColors.dislike, dark.surface), lessThan(4.5));
    });

    test('큰 글자·아이콘 기준(3:1)은 양쪽 테마에서 넘는다', () {
      for (final scheme in [light, dark]) {
        expect(contrast(AppColors.like, scheme.surface), greaterThan(3.0));
        expect(contrast(AppColors.dislike, scheme.surface), greaterThan(3.0));
      }
    });
  });
}
