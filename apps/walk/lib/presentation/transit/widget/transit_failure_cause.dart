import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 실패 원인 원문(예외 타입 · HTTP 상태 · ODsay code · msg). 길게 눌러 선택 · 복사할 수
/// 있어 실사용 중 원인을 그대로 옮겨 적을 수 있다. 키 값은 만드는 쪽에서 가린다.
class TransitFailureCause extends StatelessWidget {
  const TransitFailureCause(this.detail, {super.key});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 안내 띠 모양은 AppBanner, 글자는 SelectionArea 로 골라 복사한다.
    return SelectionArea(
      key: const Key('transit-failure-cause'),
      child: AppBanner(
        title: l10n.walkTransitFailureCause,
        message: detail,
        icon: Icons.bug_report_outlined,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
