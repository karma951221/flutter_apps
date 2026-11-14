import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../data/location/background_location_access.dart';
import '../cubit/map_record_cubit.dart';

/// 권한 흐름을 거쳐 위치 기록을 켠다. "항상 허용"을 대화상자로 못 받았으면 설정으로 보내는
/// 스낵바, 거부했으면 [설정 열기]가 달린 오류 스낵바를 띄운다. 권한 흐름 · 서비스 시작이 던지면(PlatformException 등)
/// 기록하고 오류 스낵바를 띄운다 — 부르는 쪽은 기다리지 않는다. 지도 탭(칩 · 처음 안내)과 지도
/// 설정이 함께 쓴다.
Future<void> enableLocationRecord(
  BuildContext context,
  MapRecordCubit cubit,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await cubit.enable();
  } catch (e, s) {
    debugPrint('enable location record failed: $e\n$s');
    if (!context.mounted) return;
    AppSnackBar.show(
      context,
      message: l10n.walkMapEnableFailed,
      type: AppSnackBarType.error,
    );
    return;
  }
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
      // 두 번 거부하면 안드로이드가 권한 창을 다시 띄우지 않는다 — 설정으로 가는 길을 늘 준다.
      AppSnackBar.show(
        context,
        message: l10n.walkMapSettingsDenied,
        type: AppSnackBarType.error,
        actionLabel: l10n.walkMapSettingsOpenSettings,
        onAction: cubit.openAppSettings,
      );
    case AlwaysAccess.granted || null:
      break;
  }
}
