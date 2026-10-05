import 'package:flutter/material.dart';

import '../../theme/pawlog_theme.dart';

/// 화면마다 하나뿐인 주 동작 — 하단 고정 알약 58(design.md Components · 주 버튼).
///
/// 누르면 0.97 로 줄고(120ms ease-out), 비활성은 투명도 0.4, 로딩 ↔ 라벨은 200ms
/// 크로스페이드다. [PawlogPrimaryButton.stop] 은 산책 끝내기 — 먹색으로 '멈춤' 을 구분한다.
///
/// 공용 `AppButton.primary` 를 감싸지 않고 `FilledButton` 을 직접 쓴다. `AppButton` 은
/// 라벨이 `String` 이고 로딩이면 자식을 즉시 바꿔서, 버튼 바탕은 그대로 둔 채 안쪽만
/// 크로스페이드할 수 없다. 모양(알약 · 높이 · 색 · 글자)은 `PawlogTheme` 의
/// `filledButtonTheme` 에서 오므로 `AppButton.primary` 와 같다.
class PawlogPrimaryButton extends StatefulWidget {
  const PawlogPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  }) : isStop = false;

  /// 산책 끝내기 — 먹색 변형.
  const PawlogPrimaryButton.stop({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  }) : isStop = true;

  final String label;

  /// null 이면 비활성(투명도 0.4).
  final VoidCallback? onPressed;

  /// 참이면 누를 수 없고 라벨 대신 진행 표시를 보인다. 흐려지지는 않는다.
  final bool isLoading;
  final bool isStop;

  @override
  State<PawlogPrimaryButton> createState() => _PawlogPrimaryButtonState();
}

class _PawlogPrimaryButtonState extends State<PawlogPrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(PawlogPrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = PawlogColors.of(context);
    final off = PawlogMotion.off(context);
    final background = widget.isStop ? colors.stop : colors.primary;
    final foreground = widget.isStop ? colors.onStop : colors.onPrimary;
    final disabled = widget.onPressed == null && !widget.isLoading;

    final content = widget.isLoading
        ? SizedBox.square(
            key: const ValueKey('loading'),
            dimension: PawlogSize.buttonSpinner,
            child: CircularProgressIndicator(
              strokeWidth: PawlogSize.buttonSpinnerStroke,
              color: foreground,
            ),
          )
        : Text(
            widget.label,
            key: const ValueKey('label'),
            textAlign: TextAlign.center,
          );

    return Semantics(
      container: true,
      child: AnimatedOpacity(
        opacity: disabled ? PawlogMotion.disabledOpacity : 1,
        duration: off ? Duration.zero : PawlogMotion.state,
        curve: PawlogMotion.move,
        child: Listener(
          onPointerDown: (_) {
            if (_enabled) _setPressed(true);
          },
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: _pressed ? PawlogMotion.pressedScale : 1,
            duration: off ? Duration.zero : PawlogMotion.press,
            curve: PawlogMotion.enter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: PawlogRadius.fullAll,
                boxShadow: PawlogShadows.primaryButton(colors.shadow),
              ),
              child: FilledButton(
                onPressed: _enabled ? widget.onPressed : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(background),
                  foregroundColor: WidgetStatePropertyAll(foreground),
                ),
                child: AnimatedSwitcher(
                  duration: off ? Duration.zero : PawlogMotion.state,
                  switchInCurve: PawlogMotion.enter,
                  switchOutCurve: PawlogMotion.exit,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 화면 아래에 붙는 주 버튼 자리 — 좌우 여백 20, 아래 안전 영역.
///
/// `Scaffold.bottomNavigationBar` 가 아니라 본문 `Column` 의 마지막에 둔다 — 그래야
/// 키보드가 올라와도 본문과 함께 키보드 위로 밀려 가려지지 않는다(QA P3).
class PawlogBottomAction extends StatelessWidget {
  const PawlogBottomAction({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        PawlogSize.gutter,
        PawlogSpacing.sm,
        PawlogSize.gutter,
        PawlogSpacing.lg,
      ),
      child: child,
    ),
  );
}
