import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../domain/tracking/repository/walk_tracker.dart';
import 'app.dart';
import 'di/injection.dart';
import 'supabase/supabase_initializer.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DI 가 SupabaseClient 를 쓰는 저장소를 고르려면 먼저 끝나야 한다. 실패해도 던지지 않는다 —
  // 로컬 기록은 그대로 쓰고 모두의 산책만 오류 안내를 보인다.
  final social = await initializeSupabase();
  await configureDependencies(social: social);
  // 앱이 죽기 전 진행 중이던 산책을 첫 화면 전에 되살린다.
  try {
    await getIt<WalkTracker>().restore();
  } catch (error) {
    // 복구가 실패해도 앱은 뜬다. 새 산책은 그대로 시작할 수 있다.
    debugPrint('walk restore failed: $error');
  }
  runApp(const PawlogApp());
}
