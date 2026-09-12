import 'package:flutter/material.dart';

import 'package:design_system/design_system.dart';

/// 모의투자 지표 한 칸. 라벨 위, 값 아래.
///
/// 결과 화면과 판 진행 화면이 같은 모양의 지표 칸을 쓴다. 화면마다 `Card` 를
/// 다시 쌓으면 여백과 글씨 크기가 곧 어긋나므로 한곳으로 모은다
/// (CLAUDE.md UI 공통 위젯 규칙 4 — 반복 사용되는 모양).
///
/// `design_system/widget/` 이 아니라 feature 안에 두는 이유는 이 모양이 아직
/// 모의투자 두 화면에만 쓰이기 때문이다. 다른 feature 가 같은 칸을 필요로 할
/// 때 승격한다.
class TradeMetricCard extends StatelessWidget {
  const TradeMetricCard({
    required this.label,
    required this.value,
    this.valueStyle,
    super.key,
  });

  final String label;
  final String value;

  /// 값 글씨를 바꾼다. 수익률처럼 색이나 크기로 강조하는 칸에 쓴다.
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: valueStyle ?? theme.textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

/// 지표 칸 두 장을 한 줄에 같은 너비 · 같은 높이로 놓는다.
///
/// 높이를 맞추는 이유는 글자 수가 달라 칸이 어긋나면 지표보다 배치가 먼저
/// 눈에 들어오기 때문이다. `stretch` 만으로는 세로가 무한인 목록 안에서
/// 높이를 정할 수 없어 [IntrinsicHeight] 가 함께 있어야 한다.
class TradeMetricRow extends StatelessWidget {
  const TradeMetricRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final child in children) Expanded(child: child)],
    ),
  );
}
