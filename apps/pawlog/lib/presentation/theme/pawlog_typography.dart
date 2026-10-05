import 'package:flutter/material.dart';

import 'pawlog_colors.dart';

/// 번들한 서체 이름(pubspec `fonts:`).
abstract final class PawlogFonts {
  /// 고운돋움 — 화면 제목 · 강아지 이름 · 상세 제목. 본문에 쓰지 않는다.
  static const heading = 'GowunDodum';

  /// Pretendard — 본문 · UI · 숫자 전부.
  static const body = 'Pretendard';

  /// 개구 — 사용자가 쓴 메모에만. 제목 · 버튼 · 안내문 금지.
  static const memo = 'Gaegu';
}

/// `TextTheme` 에 자리가 없는 pawlog 전용 글자 모양.
///
/// 숫자는 Pretendard 700 + 타뷸러로 1초마다 바뀌는 시간이 좌우로 흔들리지 않게 한다.
@immutable
class PawlogTextStyles extends ThemeExtension<PawlogTextStyles> {
  const PawlogTextStyles({
    required this.numberHero,
    required this.number,
    required this.memo,
    required this.dogName,
    required this.feedDay,
    required this.feedWeekday,
  });

  /// 산책 중 시트의 거리 · 시간(44).
  final TextStyle numberHero;

  /// 피드 · 상세 · 배너의 거리 · 시간(20).
  final TextStyle number;

  /// 사용자가 쓴 메모(개구 20).
  final TextStyle memo;

  /// 줄글 안의 강아지 이름(고운돋움).
  final TextStyle dogName;

  /// 피드 날짜 열의 일(30/700).
  final TextStyle feedDay;

  /// 피드 날짜 열의 요일(12 muted).
  final TextStyle feedWeekday;

  static const _tabular = [FontFeature.tabularFigures()];

  factory PawlogTextStyles.from(PawlogColors colors) => PawlogTextStyles(
    numberHero: TextStyle(
      fontFamily: PawlogFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 44,
      height: 1.1,
      letterSpacing: -1.32,
      fontFeatures: _tabular,
      color: colors.text,
    ),
    number: TextStyle(
      fontFamily: PawlogFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      height: 1.3,
      letterSpacing: -0.2,
      fontFeatures: _tabular,
      color: colors.text,
    ),
    memo: TextStyle(
      fontFamily: PawlogFonts.memo,
      fontWeight: FontWeight.w400,
      fontSize: 20,
      height: 1.35,
      color: colors.text,
    ),
    dogName: TextStyle(
      fontFamily: PawlogFonts.heading,
      fontWeight: FontWeight.w400,
      fontSize: 17,
      height: 1.3,
      color: colors.text,
    ),
    feedDay: TextStyle(
      fontFamily: PawlogFonts.body,
      fontWeight: FontWeight.w700,
      fontSize: 30,
      height: 1.1,
      letterSpacing: -0.3,
      fontFeatures: _tabular,
      color: colors.text,
    ),
    feedWeekday: TextStyle(
      fontFamily: PawlogFonts.body,
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: colors.textMuted,
    ),
  );

  static PawlogTextStyles of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<PawlogTextStyles>() ??
        PawlogTextStyles.from(PawlogColors.of(context));
  }

  @override
  PawlogTextStyles copyWith({
    TextStyle? numberHero,
    TextStyle? number,
    TextStyle? memo,
    TextStyle? dogName,
    TextStyle? feedDay,
    TextStyle? feedWeekday,
  }) => PawlogTextStyles(
    numberHero: numberHero ?? this.numberHero,
    number: number ?? this.number,
    memo: memo ?? this.memo,
    dogName: dogName ?? this.dogName,
    feedDay: feedDay ?? this.feedDay,
    feedWeekday: feedWeekday ?? this.feedWeekday,
  );

  @override
  PawlogTextStyles lerp(PawlogTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return PawlogTextStyles(
      numberHero: mix(numberHero, other.numberHero),
      number: mix(number, other.number),
      memo: mix(memo, other.memo),
      dogName: mix(dogName, other.dogName),
      feedDay: mix(feedDay, other.feedDay),
      feedWeekday: mix(feedWeekday, other.feedWeekday),
    );
  }
}

/// Material `TextTheme` — 제목(display · headline · titleLarge)은 고운돋움, 나머지는 Pretendard.
abstract final class PawlogTypography {
  static TextTheme textTheme(PawlogColors colors) {
    TextStyle heading(double size, {double letterSpacing = 0}) => TextStyle(
      fontFamily: PawlogFonts.heading,
      fontWeight: FontWeight.w400,
      fontSize: size,
      height: 1.3,
      letterSpacing: letterSpacing,
      color: colors.text,
    );
    TextStyle body(
      double size, {
      FontWeight weight = FontWeight.w400,
      double height = 1.5,
      Color? color,
    }) => TextStyle(
      fontFamily: PawlogFonts.body,
      fontWeight: weight,
      fontSize: size,
      height: height,
      color: color ?? colors.text,
    );

    return TextTheme(
      displayLarge: heading(40),
      displayMedium: heading(34),
      displaySmall: heading(30),
      // design.md display(26, -0.01em) · title(22).
      headlineLarge: heading(28),
      headlineMedium: heading(26, letterSpacing: -0.26),
      headlineSmall: heading(24),
      titleLarge: heading(22),
      titleMedium: body(16, weight: FontWeight.w500),
      titleSmall: body(14, weight: FontWeight.w500),
      // design.md body(15, 1.6).
      bodyLarge: body(15, height: 1.6),
      bodyMedium: body(14),
      bodySmall: body(12, color: colors.textMuted),
      labelLarge: body(16, weight: FontWeight.w700, height: 1.2),
      // design.md label(12, 500).
      labelMedium: body(12, weight: FontWeight.w500, height: 1.3),
      labelSmall: body(11, weight: FontWeight.w500, height: 1.3),
    );
  }
}
