import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../domain/tracking/repository/walk_tracker.dart';
import 'app.dart';
import 'di/injection.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // 앱이 죽기 전 진행 중이던 산책을 첫 화면 전에 되살린다.
  try {
    await getIt<WalkTracker>().restore();
  } catch (error) {
    // 복구가 실패해도 앱은 뜬다. 새 산책은 그대로 시작할 수 있다.
    debugPrint('walk restore failed: $error');
  }
  runApp(const PawlogApp());
}
