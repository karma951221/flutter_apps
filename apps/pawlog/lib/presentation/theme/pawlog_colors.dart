import 'package:flutter/material.dart';

/// pawlog 색 토큰([design.md](../../../docs/design.md) Colors).
///
/// 회백지 · 먹 · 회갈 중립색 위에 리드줄 남색([primary]) 하나, 테니스공 연두([accent]) 하나.
/// 연두는 경로 선 · 진행 중 점멸 점 · 목표 달성 표시에만 쓴다 — 버튼 · 배경 · 텍스트 금지.
/// 화면은 `PawlogColors.of(context)` 로 읽고 `Colors.*` 를 직접 쓰지 않는다.
@immutable
class PawlogColors extends ThemeExtension<PawlogColors> {
  const PawlogColors({
    required this.paper,
    required this.sheet,
    required this.text,
    required this.textMuted,
    required this.rule,
    required this.inputBorder,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.error,
    required this.onError,
    required this.mapBg,
    required this.mapPark,
    required this.routeCasing,
    required this.stop,
    required this.onStop,
    required this.shadow,
  });

  /// 바탕 종이. 노란 크림이 아니라 살짝 회색이 도는 종이색.
  final Color paper;

  /// 바탕보다 한 단계 올라온 면 — 시트 · 다이얼로그 · 입력칸.
  final Color sheet;
  final Color text;
  final Color textMuted;

  /// 구분선 1px. 그림자 대신 이것으로 나눈다.
  final Color rule;

  /// 입력칸 · 칩 테두리. [rule] 보다 진해 바탕과 3:1 이상 벌어진다(QA P4).
  final Color inputBorder;

  /// 누를 수 있는 것 — 주 버튼 · 진행 배너 · 링크 텍스트 · 리드줄.
  final Color primary;
  final Color onPrimary;

  /// 경로 선 · 추적 중 점멸 점에만.
  final Color accent;
  final Color onAccent;

  /// 삭제 확인 · 실패 안내에만.
  final Color error;
  final Color onError;

  /// 경로 썸네일 바탕(타일 없는 지도 자리).
  final Color mapBg;
  final Color mapPark;

  /// 경로 선 테두리. 지도 타일은 다크에서도 밝으므로 모드와 상관없이 진한 남색이다.
  final Color routeCasing;

  /// 산책 끝내기 버튼 — '멈춤' 을 먹색으로 구분한다.
  final Color stop;
  final Color onStop;

  /// 하단 주 버튼 · 지도 위 시트 두 곳의 그림자 색.
  final Color shadow;

  static const light = PawlogColors(
    paper: Color(0xFFF4F3EF),
    sheet: Color(0xFFFBFAF7),
    text: Color(0xFF24251F),
    textMuted: Color(0xFF6F6D64),
    rule: Color(0xFFDDDAD1),
    inputBorder: Color(0xFF8A877D),
    primary: Color(0xFF2C3B57),
    onPrimary: Color(0xFFF4F3EF),
    accent: Color(0xFFCFE04A),
    onAccent: Color(0xFF2C3B57),
    error: Color(0xFFB3402E),
    onError: Color(0xFFF4F3EF),
    mapBg: Color(0xFFE9E7E0),
    mapPark: Color(0xFFDCE3D2),
    routeCasing: Color(0xFF2C3B57),
    stop: Color(0xFF24251F),
    onStop: Color(0xFFF4F3EF),
    shadow: Color(0x2E24251F),
  );

  /// '밤산책' — 먹색 바탕에 남색을 밝게 올리고 연두는 그대로.
  static const dark = PawlogColors(
    paper: Color(0xFF1B1C19),
    sheet: Color(0xFF23241F),
    text: Color(0xFFECEAE3),
    textMuted: Color(0xFFA19E93),
    rule: Color(0xFF3A3B35),
    inputBorder: Color(0xFF73746A),
    primary: Color(0xFFA9B8D6),
    onPrimary: Color(0xFF1B1C19),
    accent: Color(0xFFCFE04A),
    onAccent: Color(0xFF2C3B57),
    error: Color(0xFFE0705C),
    onError: Color(0xFF1B1C19),
    mapBg: Color(0xFF23241F),
    mapPark: Color(0xFF2C3328),
    routeCasing: Color(0xFF2C3B57),
    stop: Color(0xFFECEAE3),
    onStop: Color(0xFF1B1C19),
    shadow: Color(0x66000000),
  );

  /// 테마에 확장이 없으면(테스트 등) 밝기에 맞는 기본값을 쓴다.
  static PawlogColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PawlogColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  PawlogColors copyWith({
    Color? paper,
    Color? sheet,
    Color? text,
    Color? textMuted,
    Color? rule,
    Color? inputBorder,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? onAccent,
    Color? error,
    Color? onError,
    Color? mapBg,
    Color? mapPark,
    Color? routeCasing,
    Color? stop,
    Color? onStop,
    Color? shadow,
  }) => PawlogColors(
    paper: paper ?? this.paper,
    sheet: sheet ?? this.sheet,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    rule: rule ?? this.rule,
    inputBorder: inputBorder ?? this.inputBorder,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    mapBg: mapBg ?? this.mapBg,
    mapPark: mapPark ?? this.mapPark,
    routeCasing: routeCasing ?? this.routeCasing,
    stop: stop ?? this.stop,
    onStop: onStop ?? this.onStop,
    shadow: shadow ?? this.shadow,
  );

  @override
  PawlogColors lerp(PawlogColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return PawlogColors(
      paper: mix(paper, other.paper),
      sheet: mix(sheet, other.sheet),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      rule: mix(rule, other.rule),
      inputBorder: mix(inputBorder, other.inputBorder),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      error: mix(error, other.error),
      onError: mix(onError, other.onError),
      mapBg: mix(mapBg, other.mapBg),
      mapPark: mix(mapPark, other.mapPark),
      routeCasing: mix(routeCasing, other.routeCasing),
      stop: mix(stop, other.stop),
      onStop: mix(onStop, other.onStop),
      shadow: mix(shadow, other.shadow),
    );
  }
}
