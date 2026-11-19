import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 걷기 앱 톤 — 청록빛 초록. 다른 앱과 공유하지 않으므로 design_system 이 아니라 여기 둔다.
///
/// 시트 · 카드 · 다이얼로그 · 칩 모양도 여기서 얹는다. 공유 `AppTheme` 에 넣으면
/// 트레이더 · pawlog 화면 모양까지 바뀌므로 걷기 앱에서만 `copyWith` 로 덧씌운다
/// (기준: [walk UI 가이드](../../../docs/ui-guide.md)).
abstract final class WalkTheme {
  static const seed = Color(0xFF1D9E75);

  static ThemeData light() => _components(AppTheme.light(seedColor: seed));
  static ThemeData dark() => _components(AppTheme.dark(seedColor: seed));

  static ThemeData _components(ThemeData base) {
    final scheme = base.colorScheme;
    return base.copyWith(
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        shape: appSheetShape,
        clipBehavior: Clip.antiAlias,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Icon(Icons.check)
              : null,
        ),
      ),
    );
  }
}
