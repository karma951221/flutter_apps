import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// 행 하나(AppListTile)를 감싸 "여기를 보세요"를 두 번 짚는다.
///
/// 재생 조건: [play] 가 처음부터 true 이거나 false → true 로 바뀌면 한 번, [replayToken] 이 바뀔 때마다 한 번.
/// [play] 가 true → false 로 바뀌면(짚을 행이 다른 행으로 옮겨 감) 예약을 거두고, 재생 중이면 지금 값에서 꺼 내린다.
/// 재생은 둘러싼 라우트의 push 전환이 끝난 뒤(ModalRoute.animation 완료) 다음 프레임에 시작한다.
/// 애니메이션 줄이기(AppMotion.enabled == false)면 그리지 않는다.
class RowHighlight extends StatefulWidget {
  const RowHighlight({
    required this.child,
    this.play = false,
    this.replayToken = 0,
    this.announce,
    super.key,
  });

  final Widget child;
  final bool play;
  final int replayToken;

  /// 재생을 시작할 때 SemanticsService.sendAnnouncement 로 한 번 읽을 글(보통 행 제목). null 이면 읽지 않음.
  final String? announce;

  /// 한 번 = 켜짐 medium → 유지 long → 꺼짐 medium(= 900ms). 두 번 반복.
  static const repeats = 2;
  static Duration get cycle =>
      AppMotion.medium + AppMotion.long + AppMotion.medium;

  // 아래 셋은 스펙(§3.2 glow 모양)이 정한 값이다. 토큰에 "강조 면 · 테두리" 에 해당하는
  // 불투명도 · 선 굵기가 없어 이 위젯 안에 이름을 붙여 둔다(한 곳에서만 쓰는 시각 상수).

  /// 면 채움 — primary 의 불투명도.
  static const fillAlpha = 0.12;

  /// 테두리 — primary 의 불투명도.
  static const borderAlpha = 0.6;

  /// 테두리 굵기.
  static const borderWidth = 1.5;

  @override
  State<RowHighlight> createState() => _RowHighlightState();
}

class _RowHighlightState extends State<RowHighlight>
    with TickerProviderStateMixin {
  /// 두 번 깜빡이는 본 재생.
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: RowHighlight.cycle * RowHighlight.repeats,
  );

  /// 누르거나 스크롤해서 끌 때 지금 값에서 0 으로 내리는 짧은 재생.
  late final AnimationController _fadeOut = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  late final Animation<double> _blinkOpacity = _blinkSequence().animate(_blink);

  /// 지금 FadeTransition 이 따르는 값. 본 재생이거나 끄는 중이다.
  late Animation<double> _opacity = _blinkOpacity;

  /// 재생이 예약됐거나 진행 중인지. 같은 요청이 겹치지 않게 세대 번호를 둔다.
  int _generation = 0;
  ModalRoute<Object?>? _waitingRoute;
  ScrollPosition? _watchedPosition;

  static Animatable<double> _blinkSequence() {
    double ms(Duration d) => d.inMicroseconds.toDouble();
    final rise = Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: AppMotion.standard));
    final fall = Tween<double>(
      begin: 1,
      end: 0,
    ).chain(CurveTween(curve: AppMotion.standard));
    return TweenSequence<double>([
      for (var i = 0; i < RowHighlight.repeats; i++) ...[
        TweenSequenceItem(tween: rise, weight: ms(AppMotion.medium)),
        TweenSequenceItem(
          tween: ConstantTween<double>(1),
          weight: ms(AppMotion.long),
        ),
        TweenSequenceItem(tween: fall, weight: ms(AppMotion.medium)),
      ],
    ]);
  }

  @override
  void initState() {
    super.initState();
    _blink.addStatusListener((status) {
      if (status == AnimationStatus.completed) _stopWatching();
    });
    if (widget.play) _request();
  }

  @override
  void didUpdateWidget(RowHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    final turnedOn = widget.play && !oldWidget.play;
    final replay = widget.replayToken != oldWidget.replayToken;
    if (turnedOn || replay) {
      _request();
    } else if (oldWidget.play && !widget.play) {
      _cancel();
    }
  }

  /// 예약 · 대기 중인 재생을 거두고, 재생 중이면 꺼 내린다. 빌드 중에 불리므로 setState 하지 않는다.
  void _cancel() {
    _generation++;
    _stopWaitingForRoute();
    _fadeOutRunning();
  }

  @override
  void dispose() {
    _generation++;
    _stopWaitingForRoute();
    _stopWatching();
    _blink.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  /// 재생을 예약한다. 라우트 전환 중이면 끝날 때까지 기다린다.
  void _request() {
    final generation = ++_generation;
    _stopWaitingForRoute();
    // initState · didUpdateWidget 안에서는 ModalRoute 를 읽을 수 없어 이번 프레임 뒤로 미룬다.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      final route = ModalRoute.of(context);
      final animation = route?.animation;
      if (animation == null || animation.isCompleted) {
        _start(generation);
        return;
      }
      _waitingRoute = route;
      animation.addStatusListener(_onRouteStatus);
    });
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _stopWaitingForRoute();
    final generation = _generation;
    // 전환이 끝난 프레임을 다 그린 뒤 재생을 건다 — 첫 틱은 다음 프레임.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation) _start(generation);
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _stopWaitingForRoute() {
    _waitingRoute?.animation?.removeStatusListener(_onRouteStatus);
    _waitingRoute = null;
  }

  void _start(int generation) {
    final animate = AppMotion.enabled(context);
    final text = widget.announce;
    if (text != null) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        text,
        Directionality.of(context),
      );
    }
    final policy = _revealPolicy();
    if (policy == null) {
      if (animate) _blinkNow();
      return;
    }
    // 행이 화면 밖에 걸쳐 있으면 먼저 들이고, 다 들어온 뒤 깜빡인다(스크롤이 재생을 끄지 않게).
    Scrollable.ensureVisible(
      context,
      duration: animate ? AppMotion.medium : Duration.zero,
      curve: AppMotion.standard,
      alignmentPolicy: policy,
    ).then((_) {
      if (mounted && generation == _generation && animate) _blinkNow();
    });
  }

  void _blinkNow() {
    _stopWatching();
    _fadeOut.reset();
    setState(() => _opacity = _blinkOpacity);
    _watchedPosition = Scrollable.maybeOf(context)?.position
      ?..addListener(_dismiss);
    _blink.forward(from: 0);
  }

  /// 행이 스크롤 화면 밖에 걸쳐 있으면 가까운 끝으로 들일 정책. 다 보이면 null.
  ScrollPositionAlignmentPolicy? _revealPolicy() {
    final position = Scrollable.maybeOf(context)?.position;
    final box = context.findRenderObject();
    if (position == null || box == null || !box.attached) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    final atStart = viewport.getOffsetToReveal(box, 0).offset;
    final atEnd = viewport.getOffsetToReveal(box, 1).offset;
    if (position.pixels > atStart) {
      return ScrollPositionAlignmentPolicy.keepVisibleAtStart;
    }
    if (position.pixels < atEnd) {
      return ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
    }
    return null;
  }

  /// 재생 중 누르거나 스크롤하면 지금 값에서 0 으로 내리고 멈춘다.
  void _dismiss() {
    if (!_blink.isAnimating) return;
    setState(_fadeOutRunning);
  }

  /// 본 재생 중이면 지금 값에서 0 으로 내리는 재생으로 바꾼다(AppMotion.medium).
  void _fadeOutRunning() {
    if (!_blink.isAnimating) return;
    _stopWatching();
    final from = _blinkOpacity.value;
    _blink.stop();
    _opacity = Tween<double>(
      begin: from,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeOut, curve: AppMotion.standard));
    _fadeOut.forward(from: 0);
  }

  void _stopWatching() {
    _watchedPosition?.removeListener(_dismiss);
    _watchedPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    final child = Listener(
      onPointerDown: (_) => _dismiss(),
      child: widget.child,
    );
    if (!AppMotion.enabled(context)) return child;
    final primary = Theme.of(context).colorScheme.primary;
    // 면은 행 뒤에 깐다 — 글자 · 아이콘을 덮지 않는다.
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: FadeTransition(
                key: const Key('row-highlight-glow'),
                opacity: _opacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.smAll,
                    color: primary.withValues(alpha: RowHighlight.fillAlpha),
                    border: Border.all(
                      color: primary.withValues(
                        alpha: RowHighlight.borderAlpha,
                      ),
                      width: RowHighlight.borderWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
