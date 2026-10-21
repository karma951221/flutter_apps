import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 스토리 뷰어 맨 위 진행 막대: 그날 조각마다 한 칸. [index] 앞은 다 찼고, [index] 칸은
/// [progress] 만큼, 뒤는 비었다.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    required this.count,
    required this.index,
    required this.progress,
    super.key,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  /// 막대 굵기. 시각 토큰이 아니라 이 위젯의 크기다.
  static const _height = 2.0;

  /// 빈 칸의 불투명도.
  static const _trackAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: SizedBox(
                height: _height,
                child: i == index
                    ? AnimatedBuilder(
                        animation: progress,
                        builder: (context, _) =>
                            _Fill(value: progress.value, color: color),
                      )
                    : _Fill(value: i < index ? 1 : 0, color: color),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color.withValues(alpha: StoryProgressBar._trackAlpha),
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: value.clamp(0, 1),
      child: ColoredBox(color: color),
    ),
  );
}
