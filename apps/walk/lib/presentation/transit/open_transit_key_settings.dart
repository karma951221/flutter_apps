import 'package:flutter/material.dart';

import '../settings/page/transit_settings_page.dart';

/// 길찾기 키 설정 화면을 연다. 닫히면 끝난다.
Future<void> openTransitKeySettings(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const TransitSettingsPage()));
