import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../domain/tracking/repository/walk_tracker.dart';
import 'app.dart';
import 'di/injection.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  // 앱이 죽기 전 진행 중이던 산책을 첫 화면 전에 되살린다.
  await getIt<WalkTracker>().restore();
  runApp(const PawlogApp());
}
