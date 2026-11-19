import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk/presentation/theme/walk_theme.dart';

void main() {
  test('walk 테마는 초록 시드다', () {
    expect(
      WalkTheme.light().colorScheme.primary,
      ColorScheme.fromSeed(seedColor: WalkTheme.seed).primary,
    );
  });

  test('시트 · 카드 · 다이얼로그 모양을 걷기 테마에서만 얹는다', () {
    for (final theme in [WalkTheme.light(), WalkTheme.dark()]) {
      final scheme = theme.colorScheme;
      expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      expect(theme.bottomSheetTheme.shape, appSheetShape);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, scheme.surfaceContainerLow);
      expect(
        theme.cardTheme.shape,
        const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      );
      expect(
        theme.dialogTheme.shape,
        const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      );
    }
    // 공유 테마는 그대로 — 다른 앱 모양이 바뀌지 않는다.
    expect(AppTheme.light().cardTheme.elevation, isNull);
    expect(AppTheme.light().bottomSheetTheme.showDragHandle, isNull);
  });
}
