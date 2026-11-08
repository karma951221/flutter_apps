import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../data/location/background_location_access.dart';
import '../cubit/map_record_cubit.dart';

/// 권한 흐름을 거쳐 위치 기록을 켠다. "항상 허용"을 대화상자로 못 받았으면 설정으로 보내는
/// 스낵바, 거부했으면 오류 스낵바를 띄운다. 지도 탭(칩 · 처음 안내)과 지도 설정이 함께 쓴다.
Future<void> enableLocationRecord(
  BuildContext context,
  MapRecordCubit cubit,
) async {
  final l10n = AppLocalizations.of(context);
  await cubit.enable();
  if (!context.mounted) return;
  switch (cubit.state.access) {
    case AlwaysAccess.needsSettings:
      AppSnackBar.show(
        context,
        message: l10n.walkMapSettingsNeedsAlways,
        actionLabel: l10n.walkMapSettingsOpenSettings,
        onAction: cubit.openAppSettings,
      );
    case AlwaysAccess.denied:
      AppSnackBar.show(
        context,
        message: l10n.walkMapSettingsDenied,
        type: AppSnackBarType.error,
      );
    case AlwaysAccess.granted || null:
      break;
  }
}
