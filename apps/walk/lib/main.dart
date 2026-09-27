import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'core/app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 이전 세션의 예약을 다시 걸고 알림 스누즈 기록을 반영한다. DI 의 스케줄러가 쓰기 전에 끝나야 한다.
  await Alarm.init();
  configureDependencies();
  runApp(const WalkApp());
}
