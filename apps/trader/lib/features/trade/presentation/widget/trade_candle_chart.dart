import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/trade_candle.dart';
import '../../domain/entity/trade_order.dart';
import '../../domain/entity/trade_side.dart';
import '../../domain/trade_rules.dart';
import '../format/trade_format.dart';

/// 판 하나를 통째로 보여주는 캔들 차트.
///
/// 가로 스크롤이 없다. x 축은 판이 끝났을 때의 봉 개수([totalCandles])로 항상
/// 같게 나뉘고, 아직 공개되지 않은 오른쪽은 비워 둔다 — 워밍업만 보이는
/// 시점에는 왼쪽 절반만 차고, step 이 진행될수록 오른쪽으로 자란다. 판이
/// 진행돼도 이미 그린 봉의 x 위치가 움직이지 않는 게 목적이다.
class TradeCandleChart extends StatelessWidget {
  const TradeCandleChart({
    required this.candles,
    this.orders = const [],
    this.warmupCount = TradeRules.warmupCandles,
    this.totalCandles = TradeRules.totalCandles,
    this.endIndex,
    this.height = defaultHeight,
    super.key,
  });

  /// 차트 기본 높이. 봉 120개가 뭉개지지 않는 최소선이다.
  static const defaultHeight = 240.0;

  /// 지금까지 공개된 봉. index 0..(59 + step) 이 순서대로 온다.
  final List<TradeCandle> candles;

  /// 체결된 주문. 봉 위에 매수 ▲ · 매도 ▼ 로 찍는다.
  final List<TradeOrder> orders;

  /// 매매할 수 없는 워밍업 구간의 봉 개수. 배경으로 구분한다.
  final int warmupCount;

  /// x 축을 나누는 슬롯 수. 실제로 그려진 봉 수와 무관하게 고정이다.
  final int totalCandles;

  /// 판이 끝난 위치. 결과 화면에서 세로선으로 표시한다. 진행 중이면 null.
  final int? endIndex;

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final semanticsLabel = candles.isEmpty
        ? l10n.tradeChartEmptySemantics(totalCandles)
        : l10n.tradeChartSemantics(
            candles.length,
            totalCandles,
            TradeFormat.amount(candles.last.close, l10n.localeName),
          );

    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            size: Size.infinite,
            painter: TradeCandleChartPainter(
              candles: candles,
              orders: orders,
              warmupCount: warmupCount,
              totalCandles: totalCandles,
              endIndex: endIndex,
              upColor: AppColors.candleUp,
              downColor: AppColors.candleDown,
              warmupColor: scheme.surfaceContainerHighest,
              gridColor: scheme.outlineVariant,
              axisColor: scheme.outline,
              labelStyle:
                  theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ) ??
                  TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// 주문 하나가 찍힐 자리.
///
/// 그리기 결과를 테스트에서 확인하려고 [TradeCandleChartPainter.markers] 가
/// 돌려주는 화면 좌표다. 도메인 모델도 상태도 아니라서 Freezed 를 쓰지 않는다.
@immutable
class TradeMarker {
  const TradeMarker({
    required this.index,
    required this.side,
    required this.position,
  });

  /// 주문이 얹힌 봉의 index(= warmupCount − 1 + step).
  final int index;
  final TradeSide side;

  /// 삼각형의 중심. 매수는 봉 저가 아래, 매도는 봉 고가 위다.
  final Offset position;

  @override
  bool operator ==(Object other) =>
      other is TradeMarker &&
      other.index == index &&
      other.side == side &&
      other.position == position;

  @override
  int get hashCode => Object.hash(index, side, position);

  @override
  String toString() => 'TradeMarker(index: $index, side: $side, $position)';
}

/// [TradeCandleChart] 의 실제 그리기.
///
/// 레이아웃 계산은 전부 순수 함수라 [paint] 없이도 검증할 수 있다.
class TradeCandleChartPainter extends CustomPainter {
  TradeCandleChartPainter({
    required this.candles,
    required this.orders,
    required this.warmupCount,
    required this.totalCandles,
    required this.endIndex,
    required this.upColor,
    required this.downColor,
    required this.warmupColor,
    required this.gridColor,
    required this.axisColor,
    required this.labelStyle,
  });

  final List<TradeCandle> candles;
  final List<TradeOrder> orders;
  final int warmupCount;
  final int totalCandles;
  final int? endIndex;
  final Color upColor;
  final Color downColor;
  final Color warmupColor;
  final Color gridColor;
  final Color axisColor;
  final TextStyle labelStyle;

  /// 오른쪽은 y 눈금 라벨, 아래쪽은 x 라벨 자리로 비운다.
  static const _leftInset = AppSpacing.xs;
  static const _topInset = AppSpacing.sm;
  static const _rightInset = AppSpacing.xl;
  static const _bottomInset = AppSpacing.lg;

  /// 봉 몸통이 슬롯에서 차지하는 비율. 나머지는 봉 사이 간격이다.
  static const _bodyRatio = 0.6;

  /// 봉 끝과 마커 사이, 그리고 마커 한 변의 크기.
  static const _markerGap = AppSpacing.sm;
  static const _markerSize = AppSpacing.sm;

  /// 값 범위가 위아래 끝에 붙지 않게 두는 여유(범위 대비 비율).
  static const _rangePadRatio = 0.08;

  /// 봉과 눈금을 그리는 영역. 라벨 자리를 뺀 나머지다.
  Rect plotRect(Size size) => Rect.fromLTRB(
    _leftInset,
    _topInset,
    math.max(_leftInset, size.width - _rightInset),
    math.max(_topInset, size.height - _bottomInset),
  );

  /// 봉 하나가 차지하는 x 폭. 그려진 봉 수가 아니라 [totalCandles] 기준이다.
  double slotWidth(Size size) {
    if (totalCandles <= 0) return 0;
    return plotRect(size).width / totalCandles;
  }

  /// 봉 [i] 의 중심 x.
  double xForIndex(int i, Size size) =>
      plotRect(size).left + slotWidth(size) * (i + 0.5);

  /// 워밍업 구간의 오른쪽 끝(= [warmupCount] 번째 슬롯의 왼쪽 경계).
  double warmupBoundaryX(Size size) =>
      plotRect(size).left + slotWidth(size) * warmupCount;

  /// 값 [price] 의 y. 위가 고가, 아래가 저가다.
  double yForPrice(double price, Size size) {
    final plot = plotRect(size);
    final range = _paddedRange();
    if (range == null) return plot.center.dy;
    final ratio = (price - range.min) / (range.max - range.min);
    return plot.bottom - ratio * plot.height;
  }

  /// 주문마다 하나씩, 찍을 자리를 계산한다.
  List<TradeMarker> markers(Size size) {
    if (orders.isEmpty) return const [];
    final byIndex = {for (final candle in candles) candle.index: candle};

    return [
      for (final order in orders)
        () {
          final index = warmupCount - 1 + order.step;
          final candle = byIndex[index];
          final x = xForIndex(index, size);
          final y = switch (order.side) {
            TradeSide.buy =>
              yForPrice(candle?.low ?? order.price, size) + _markerGap,
            TradeSide.sell =>
              yForPrice(candle?.high ?? order.price, size) - _markerGap,
          };
          return TradeMarker(
            index: index,
            side: order.side,
            position: Offset(x, y),
          );
        }(),
    ];
  }

  /// 보이는 봉의 low~high 를 덮는 3~4개의 "예쁜" 눈금값.
  ///
  /// 보이는 봉이 없으면 빈 목록이다.
  List<double> yTicks() {
    final range = _rawRange();
    if (range == null) return const [];

    var (min, max) = (range.min, range.max);
    if (max - min < 1e-9) {
      // 완전히 평평한 구간. 눈금이 하나도 안 잡히지 않게 폭을 준다.
      min -= 1;
      max += 1;
    }

    final startExponent = (math.log((max - min) / 4) / math.ln10).floor() - 1;
    for (var e = startExponent; e <= startExponent + 6; e++) {
      final magnitude = math.pow(10, e).toDouble();
      for (final mantissa in const [1.0, 2.0, 2.5, 5.0]) {
        final step = mantissa * magnitude;
        if (step <= 0) continue;
        final first = (min / step).ceil() * step;
        final count = ((max - first) / step).floor() + 1;
        // 후보 step 은 계속 커지므로 count 는 줄기만 한다. 3개 밑으로 떨어졌다면
        // 3~4개 구간을 건너뛴 것이라 더 볼 것이 없다.
        if (count < 3) return _evenTicks(min, max);
        if (count <= 4) {
          return [for (var i = 0; i < count; i++) first + step * i];
        }
      }
    }

    return _evenTicks(min, max);
  }

  /// "예쁜" 눈금이 잡히지 않을 때 쓰는 균등 3개.
  static List<double> _evenTicks(double min, double max) => [
    min,
    (min + max) / 2,
    max,
  ];

  /// [ticks] 의 라벨. 간격(step)이 1 미만이면 [tick]을 정수로 반올림해
  /// 표시할 자리수를 정한다.
  ///
  /// [yTicks]가 고르는 간격은 0.25·0.5 처럼 1보다 작을 수 있다 — 그때
  /// `toStringAsFixed(0)` 으로 찍으면 "100 100 101 101" 처럼 서로 다른
  /// 눈금이 같은 라벨로 겹친다. [ticks] 사이의 실제 간격에서 소수 자리수를
  /// 거꾸로 구해 겹치지 않게 한다.
  String yTickLabel(double tick, List<double> ticks) =>
      tick.toStringAsFixed(_decimalsForTicks(ticks));

  static int _decimalsForTicks(List<double> ticks) {
    if (ticks.length < 2) return 0;
    final sorted = [...ticks]..sort();
    var step = double.infinity;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i] - sorted[i - 1];
      if (gap > 1e-9 && gap < step) step = gap;
    }
    if (!step.isFinite) return 0;

    // step 이 정수로 딱 떨어질 때까지 10을 곱해 가며 필요한 소수 자리수를 센다
    // (0.25 → 2, 0.5 → 1, 1 이상 → 0).
    var decimals = 0;
    var scaled = step;
    while (decimals < 6 && (scaled - scaled.roundToDouble()).abs() > 1e-6) {
      scaled *= 10;
      decimals++;
    }
    return decimals;
  }

  /// 봉 [index] 의 x 축 라벨. index 59 가 D0, 그 앞은 U+2212 로 뺀다.
  String labelForIndex(int index) {
    final offset = index - (warmupCount - 1);
    if (offset == 0) return 'D0';
    if (offset < 0) return 'D−${-offset}';
    return 'D+$offset';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = plotRect(size);
    if (plot.width <= 0 || plot.height <= 0) return;

    _paintWarmupBackground(canvas, size, plot);
    _paintYAxis(canvas, size, plot);
    _paintBoundaries(canvas, size, plot);
    _paintCandles(canvas, size, plot);
    _paintMarkers(canvas, size);
    _paintXLabels(canvas, size, plot);
  }

  void _paintWarmupBackground(Canvas canvas, Size size, Rect plot) {
    if (warmupCount <= 0) return;
    final right = math.min(warmupBoundaryX(size), plot.right);
    canvas.drawRect(
      Rect.fromLTRB(plot.left, plot.top, right, plot.bottom),
      Paint()..color = warmupColor,
    );
  }

  void _paintYAxis(Canvas canvas, Size size, Rect plot) {
    final line = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final ticks = yTicks();
    for (final tick in ticks) {
      final y = yForPrice(tick, size);
      if (y < plot.top || y > plot.bottom) continue;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), line);

      final label = _layoutLabel(yTickLabel(tick, ticks));
      label.paint(
        canvas,
        Offset(plot.right + AppSpacing.xs, y - label.height / 2),
      );
    }
  }

  void _paintBoundaries(Canvas canvas, Size size, Rect plot) {
    final line = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final boundary = warmupBoundaryX(size);
    if (boundary >= plot.left && boundary <= plot.right) {
      canvas.drawLine(
        Offset(boundary, plot.top),
        Offset(boundary, plot.bottom),
        line,
      );
    }

    final end = endIndex;
    if (end != null) {
      final x = xForIndex(end, size);
      if (x >= plot.left && x <= plot.right) {
        canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), line);
      }
    }
  }

  void _paintCandles(Canvas canvas, Size size, Rect plot) {
    final slot = slotWidth(size);
    if (slot <= 0) return;
    final bodyWidth = math.max(slot * _bodyRatio, 1.0);

    for (final candle in candles) {
      final x = xForIndex(candle.index, size);
      if (x < plot.left || x > plot.right) continue;

      final color = candle.close >= candle.open ? upColor : downColor;
      final paint = Paint()
        ..color = color
        ..strokeWidth = math.max(slot * 0.12, 1.0);

      canvas.drawLine(
        Offset(x, yForPrice(candle.high, size)),
        Offset(x, yForPrice(candle.low, size)),
        paint,
      );

      final openY = yForPrice(candle.open, size);
      final closeY = yForPrice(candle.close, size);
      final top = math.min(openY, closeY);
      final bottom = math.max(openY, closeY);
      canvas.drawRect(
        Rect.fromLTRB(
          x - bodyWidth / 2,
          top,
          x + bodyWidth / 2,
          // 시가 = 종가면 납작한 선이라도 보이게 한다.
          math.max(bottom, top + 1),
        ),
        paint,
      );
    }
  }

  void _paintMarkers(Canvas canvas, Size size) {
    for (final marker in markers(size)) {
      final center = marker.position;
      final half = _markerSize / 2;
      final path = Path();
      switch (marker.side) {
        case TradeSide.buy:
          path
            ..moveTo(center.dx, center.dy - half)
            ..lineTo(center.dx + half, center.dy + half)
            ..lineTo(center.dx - half, center.dy + half);
        case TradeSide.sell:
          path
            ..moveTo(center.dx, center.dy + half)
            ..lineTo(center.dx + half, center.dy - half)
            ..lineTo(center.dx - half, center.dy - half);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = marker.side == TradeSide.buy ? upColor : downColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintXLabels(Canvas canvas, Size size, Rect plot) {
    if (totalCandles <= 0) return;
    final indexes = {0, warmupCount - 1, totalCandles - 1}
      ..removeWhere((index) => index < 0 || index >= totalCandles);

    for (final index in indexes) {
      final label = _layoutLabel(labelForIndex(index));
      // 첫·마지막 라벨이 차트 밖으로 나가지 않게 폭 안으로 민다.
      final x = math.min(
        math.max(xForIndex(index, size) - label.width / 2, 0.0),
        math.max(size.width - label.width, 0.0),
      );
      label.paint(canvas, Offset(x, plot.bottom + AppSpacing.xs));
    }
  }

  TextPainter _layoutLabel(String text) => TextPainter(
    text: TextSpan(text: text, style: labelStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  ({double min, double max})? _rawRange() {
    if (candles.isEmpty) return null;
    var min = candles.first.low;
    var max = candles.first.high;
    for (final candle in candles) {
      min = math.min(min, candle.low);
      max = math.max(max, candle.high);
    }
    return (min: min, max: max);
  }

  ({double min, double max})? _paddedRange() {
    final range = _rawRange();
    if (range == null) return null;
    final span = range.max - range.min;
    // 완전히 평평하면 0으로 나누게 되므로 최소 폭을 준다.
    final pad = span < 1e-9 ? 1.0 : span * _rangePadRatio;
    return (min: range.min - pad, max: range.max + pad);
  }

  @override
  bool shouldRepaint(TradeCandleChartPainter oldDelegate) =>
      !listEquals(oldDelegate.candles, candles) ||
      !listEquals(oldDelegate.orders, orders) ||
      oldDelegate.warmupCount != warmupCount ||
      oldDelegate.totalCandles != totalCandles ||
      oldDelegate.endIndex != endIndex ||
      oldDelegate.upColor != upColor ||
      oldDelegate.downColor != downColor ||
      oldDelegate.warmupColor != warmupColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.axisColor != axisColor ||
      oldDelegate.labelStyle != labelStyle;
}
