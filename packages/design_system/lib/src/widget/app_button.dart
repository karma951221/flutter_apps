import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';

/// 앱 전체에서 사용하는 버튼의 공통 진입점.
///
/// 기본 모양은 [AppTheme]을 따르고, 화면별 조정은 [style]로 덧씌운다.
///
/// [animateLoading] 을 켜면 라벨과 로딩 스피너가 뚝 바뀌지 않고 서로 겹쳐
/// 페이드·스케일로 넘어간다. 기본은 꺼짐. `text` 변형은 로딩 상태가 없어 받지 않는다.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.animateLoading = false,
    this.style,
    this.compact = false,
    super.key,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.animateLoading = false,
    this.style,
    this.compact = false,
    super.key,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.style,
    this.compact = false,
    super.key,
  }) : isLoading = false,
       animateLoading = false,
       _variant = _AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// 라벨 ↔ 로딩 스피너 전환을 애니메이션으로 보여줄지. 기본 false.
  ///
  /// 켜도 시스템 '애니메이션 줄이기'면 전환 없이 바로 바꾼다.
  final bool animateLoading;
  final ButtonStyle? style;

  /// 상단 바 액션 · 다이얼로그 버튼처럼 좁은 자리용 작은 크기.
  ///
  /// 기본 버튼은 테마가 폭을 꽉 채우고(`Size.fromHeight(48)`) 높이를 48 로 잡는다.
  /// `Row` · `AppBar.actions` 안에서는 그 폭이 무한대라 터지므로, 화면마다
  /// `minimumSize: Size.zero` 같은 우회를 적지 말고 이 값을 켠다. [style] 이
  /// 같은 속성을 주면 [style] 이 이긴다.
  final bool compact;
  final _AppButtonVariant _variant;

  static final _compactStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(_compactMinWidth, 40)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.md),
    ),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final style = compact
        ? this.style?.merge(_compactStyle) ?? _compactStyle
        : this.style;
    final content = isLoading
        ? const SizedBox(
            key: ValueKey('loading'),
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        // 좁은 폭에서 줄이 바뀌어도 버튼 가운데에 맞춘다(한 줄이면 차이 없음).
        : Text(
            label,
            key: const ValueKey('label'),
            textAlign: TextAlign.center,
          );
    final child = animateLoading && AppMotion.enabled(context)
        ? AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(Tween(begin: _enterScale, end: 1)),
                child: child,
              ),
            ),
            // 나가는 것과 들어오는 것을 가운데 겹쳐 둔다 — 전환 중에 둘이 나란히
            // 놓이며 버튼 폭이 출렁이지 않게.
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.center,
              children: [...previous, ?current],
            ),
            child: content,
          )
        : content;

    return switch (_variant) {
      _AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      ),
      _AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      ),
      _AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      ),
    };
  }
}

/// 들어오는 라벨·스피너가 출발하는 배율. 0 에서 시작하면 점처럼 튀어나와 거칠다.
const _enterScale = 0.8;

/// compact 버튼의 최소 폭 — Material 3 버튼 최소 폭.
const _compactMinWidth = 64.0;

enum _AppButtonVariant { primary, secondary, text }
