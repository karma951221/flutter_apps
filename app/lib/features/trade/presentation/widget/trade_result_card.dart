import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/trade_result_summary.dart';
import '../format/trade_format.dart';

/// 게시물에 붙은 판 결과 한 장.
///
/// 피드의 `PostTile` 과 작성 화면의 미리보기가 같은 카드를 쓴다. 차트는 없다 —
/// 목록에서 스무 장이 스크롤되는 자리라 그릴 수 있는 것은 숫자 몇 개뿐이고,
/// 판을 자세히 보고 싶은 사람은 카드를 눌러 결과 화면으로 간다.
///
/// [onTap] 이 null 이면 아무 데도 가지 않는다. 작성 화면 미리보기처럼 "이게
/// 함께 올라간다"만 보여주는 자리를 위해서다.
class TradeResultCard extends StatelessWidget {
  const TradeResultCard({required this.summary, this.onTap, super.key});

  final TradeResultSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      // 잉크 물결을 카드 모서리에 맞춰 자른다. InkWell 에 반지름을 다시 적으면
      // 카드 모양이 바뀔 때 둘이 어긋난다.
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${summary.displaySymbol} · '
                '${TradeFormat.dayRange(summary.startDay, summary.endDay)}',
                style: mutedStyle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                TradeFormat.signedPct(summary.returnPct),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: _returnColor(summary.returnPct),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                [
                  l10n.tradeCardBuyHold(
                    TradeFormat.signedPct(summary.buyHoldReturnPct),
                  ),
                  // 낙폭은 0 이상으로 오지만 읽는 사람에겐 아래로 내려간 폭이다.
                  // 결과 화면과 같은 방향으로 부호를 뒤집는다.
                  l10n.tradeCardMaxDrawdown(
                    TradeFormat.signedPct(-summary.maxDrawdownPct),
                  ),
                  l10n.tradeCardCount(summary.tradeCount),
                ].join(' · '),
                style: mutedStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 0 은 색을 주지 않는다. 오르지도 내리지도 않은 것을 빨강이나 파랑으로
  /// 칠하면 없는 방향을 말하는 셈이다 (결과 화면과 같은 규칙).
  static Color? _returnColor(double returnPct) {
    if (returnPct > 0) return AppColors.candleUp;
    if (returnPct < 0) return AppColors.candleDown;
    return null;
  }
}
