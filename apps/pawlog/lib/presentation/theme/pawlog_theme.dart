import 'package:flutter/material.dart';

import 'pawlog_colors.dart';
import 'pawlog_radius.dart';
import 'pawlog_spacing.dart';
import 'pawlog_typography.dart';

export 'pawlog_colors.dart';
export 'pawlog_elevation.dart';
export 'pawlog_motion.dart';
export 'pawlog_radius.dart';
export 'pawlog_spacing.dart';
export 'pawlog_typography.dart';

/// pawlog 테마 — 산책 수첩([design.md](../../../docs/design.md)).
///
/// 공용 `AppTheme`(M3 `fromSeed`) 대신 색을 하나하나 정한다. 공용 위젯(`AppButton` ·
/// `AppPlaceholder` · `AppConfirmDialog` …)은 그대로 쓰고 모양은 여기 컴포넌트 테마로 바꾼다.
/// 다른 앱과 공유하지 않으므로 design_system 이 아니라 앱 안에 둔다(walk 의 `WalkTheme` 선례).
abstract final class PawlogTheme {
  static ThemeData light() => _build(Brightness.light, PawlogColors.light);
  static ThemeData dark() => _build(Brightness.dark, PawlogColors.dark);

  static ThemeData _build(Brightness brightness, PawlogColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      // 아바타 이니셜 바탕 — 색을 늘리지 않으려고 중립색 위에 남색 글자.
      primaryContainer: c.rule,
      onPrimaryContainer: c.primary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      secondaryContainer: c.rule,
      onSecondaryContainer: c.text,
      tertiary: c.primary,
      onTertiary: c.onPrimary,
      error: c.error,
      onError: c.onError,
      surface: c.paper,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.sheet,
      surfaceContainerLow: c.sheet,
      surfaceContainer: c.sheet,
      surfaceContainerHigh: c.sheet,
      surfaceContainerHighest: c.mapBg,
      surfaceTint: c.paper,
      outline: c.inputBorder,
      outlineVariant: c.rule,
      shadow: c.shadow,
      scrim: c.text,
      inverseSurface: c.text,
      onInverseSurface: c.paper,
      inversePrimary: c.onPrimary,
    );
    final text = PawlogTypography.textTheme(c);
    const pill = StadiumBorder();

    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: PawlogRadius.controlAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: PawlogFonts.body,
      textTheme: text,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      dividerColor: c.rule,
      extensions: [c, PawlogTextStyles.from(c)],
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.text,
        surfaceTintColor: c.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      // 주 버튼(AppButton.primary) — 알약 58. 비활성 · 로딩의 흐림은 PawlogPrimaryButton 이
      // 투명도로 맡으므로 여기서는 상태와 상관없이 같은 색이다.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.fromHeight(PawlogSize.primaryButton),
          ),
          shape: const WidgetStatePropertyAll(pill),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(c.primary),
          foregroundColor: WidgetStatePropertyAll(c.onPrimary),
          overlayColor: WidgetStatePropertyAll(
            c.onPrimary.withValues(alpha: 0.12),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: PawlogSpacing.lg),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(PawlogSpacing.xxl),
          shape: pill,
          foregroundColor: c.primary,
          side: BorderSide(color: c.inputBorder),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(
            PawlogSpacing.xxl - PawlogSpacing.xs,
          ),
          foregroundColor: c.primary,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        shape: pill,
        elevation: 0,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.sheet,
        border: inputBorder(c.inputBorder),
        enabledBorder: inputBorder(c.inputBorder),
        disabledBorder: inputBorder(c.rule),
        focusedBorder: inputBorder(c.primary, width: PawlogSize.leadLine),
        errorBorder: inputBorder(c.error),
        focusedErrorBorder: inputBorder(c.error, width: PawlogSize.leadLine),
        labelStyle: text.bodyLarge?.copyWith(color: c.textMuted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: c.primary),
        hintStyle: text.bodyLarge?.copyWith(color: c.textMuted),
        errorStyle: text.labelMedium?.copyWith(color: c.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PawlogSpacing.md,
          vertical: PawlogSpacing.md,
        ),
      ),
      // 선택은 바탕 · 테두리로만 — 체크 표시가 아바타를 가리지 않게(QA P2).
      chipTheme: ChipThemeData(
        showCheckmark: false,
        shape: pill,
        color: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.primary : c.sheet,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? c.primary
                : c.inputBorder,
          ),
        ),
        labelStyle: text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? c.onPrimary : c.text,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlogSpacing.xs,
          vertical: PawlogSpacing.xs,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.sheet,
        surfaceTintColor: c.sheet,
        shape: const RoundedRectangleBorder(
          borderRadius: PawlogRadius.sheetAll,
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheet,
        surfaceTintColor: c.sheet,
        modalBackgroundColor: c.sheet,
        dragHandleColor: c.rule,
        shape: const RoundedRectangleBorder(
          borderRadius: PawlogRadius.sheetTop,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.sheet,
        surfaceTintColor: c.sheet,
        shape: const RoundedRectangleBorder(
          borderRadius: PawlogRadius.controlAll,
        ),
        textStyle: text.bodyLarge,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.sheet,
        surfaceTintColor: c.sheet,
        headerHeadlineStyle: text.headlineMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: PawlogRadius.sheetAll,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: PawlogRadius.controlAll,
        ),
        backgroundColor: c.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.paper),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PawlogSize.gutter,
          vertical: PawlogSpacing.xs,
        ),
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: c.textMuted),
        iconColor: c.textMuted,
      ),
      dividerTheme: DividerThemeData(color: c.rule, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.rule,
        circularTrackColor: c.paper.withValues(alpha: 0),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionHandleColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.24),
      ),
    );
  }
}
