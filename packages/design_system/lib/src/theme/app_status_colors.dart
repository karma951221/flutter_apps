import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 상태 유형 — 안내 · 성공 · 주의 · 오류. 스낵바처럼 알림의 성격을 색과
/// 아이콘으로 나눠 보여 줄 때 쓴다.
enum AppStatus { info, success, warning, error }

/// 한 상태의 바탕색과 그 위의 글자 · 아이콘 색.
@immutable
class AppStatusColorPair {
  final Color background;
  final Color foreground;

  const AppStatusColorPair({
    required this.background,
    required this.foreground,
  });

  static AppStatusColorPair lerp(
    AppStatusColorPair a,
    AppStatusColorPair b,
    double t,
  ) => AppStatusColorPair(
    background: Color.lerp(a.background, b.background, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is AppStatusColorPair &&
      other.background == background &&
      other.foreground == foreground;

  @override
  int get hashCode => Object.hash(background, foreground);
}

/// 상태별 색 토큰. [AppTheme] 이 테마 확장으로 넣는다.
///
/// - info: 기존 스낵바와 같은 중립색(inverseSurface)
/// - success · warning: [AppColors.success] · [AppColors.warning] 시드의 container 짝
/// - error: colorScheme 의 errorContainer 짝
///
/// container 짝은 Material 3 톤 체계라 라이트 · 다크 모두 글자 대비 AA 를 넘는다
/// (`app_snack_bar_test.dart` 가 확인한다).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final AppStatusColorPair info;
  final AppStatusColorPair success;
  final AppStatusColorPair warning;
  final AppStatusColorPair error;

  const AppStatusColors({
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
  });

  factory AppStatusColors.fromScheme(ColorScheme scheme) {
    AppStatusColorPair seeded(Color seed) {
      final s = ColorScheme.fromSeed(
        seedColor: seed,
        brightness: scheme.brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      );
      return AppStatusColorPair(
        background: s.primaryContainer,
        foreground: s.onPrimaryContainer,
      );
    }

    return AppStatusColors(
      info: AppStatusColorPair(
        background: scheme.inverseSurface,
        foreground: scheme.onInverseSurface,
      ),
      success: seeded(AppColors.success),
      warning: seeded(AppColors.warning),
      error: AppStatusColorPair(
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
    );
  }

  /// 테마에 확장이 없으면(AppTheme 을 거치지 않은 테마) colorScheme 에서 만든다.
  static AppStatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppStatusColors>() ??
        AppStatusColors.fromScheme(theme.colorScheme);
  }

  AppStatusColorPair forStatus(AppStatus status) => switch (status) {
    AppStatus.info => info,
    AppStatus.success => success,
    AppStatus.warning => warning,
    AppStatus.error => error,
  };

  @override
  AppStatusColors copyWith({
    AppStatusColorPair? info,
    AppStatusColorPair? success,
    AppStatusColorPair? warning,
    AppStatusColorPair? error,
  }) => AppStatusColors(
    info: info ?? this.info,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
  );

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      info: AppStatusColorPair.lerp(info, other.info, t),
      success: AppStatusColorPair.lerp(success, other.success, t),
      warning: AppStatusColorPair.lerp(warning, other.warning, t),
      error: AppStatusColorPair.lerp(error, other.error, t),
    );
  }
}
