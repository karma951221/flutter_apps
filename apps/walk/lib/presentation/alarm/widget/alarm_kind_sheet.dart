import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 새 알람의 종류. 저장값이 아니다 — 저장된 알람은 `repeat` 가 비었는지로 가린다.
enum AlarmKind { oneShot, repeating }

/// `+` 를 누르면 뜨는 종류 시트 — 손잡이 · 제목 · [한 번] · [반복] 두 행.
/// 고르면 그 종류를, 그냥 닫으면 null 을 돌려준다.
class AlarmKindSheet extends StatelessWidget {
  const AlarmKindSheet({super.key});

  static Future<AlarmKind?> show(BuildContext context) =>
      showAppSheet<AlarmKind>(context: context, builder: (_) => const AlarmKindSheet());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppSheetScaffold(
      title: l10n.walkAlarmKindTitle,
      children: [
        AppListTile(
          leading: const Icon(Icons.hourglass_bottom),
          title: Text(l10n.walkAlarmKindOneShot),
          subtitle: Text(l10n.walkAlarmKindOneShotHint),
          onTap: () => Navigator.of(context).pop(AlarmKind.oneShot),
        ),
        AppListTile(
          leading: const Icon(Icons.repeat),
          title: Text(l10n.walkAlarmKindRepeat),
          subtitle: Text(l10n.walkAlarmKindRepeatHint),
          onTap: () => Navigator.of(context).pop(AlarmKind.repeating),
        ),
      ],
    );
  }
}
