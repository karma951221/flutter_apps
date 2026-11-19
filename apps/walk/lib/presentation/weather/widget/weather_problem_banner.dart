import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 예보 위 한 줄 알림 — 왜 이 예보를 보이는지(위치 · 네트워크 실패).
class WeatherProblemBanner extends StatelessWidget {
  const WeatherProblemBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => AppBanner(message: message);
}
