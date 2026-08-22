import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/network/secure_supabase_storage.dart';

/// 앱 부팅.
///
/// 순서가 중요하다.
/// 1) Supabase 초기화 — DI 가 SupabaseClient 를 꺼내려면 먼저 끝나야 한다
/// 2) DI 구성
/// 3) 실행
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO(0단계 이후): 크래시 리포팅 연결
  };

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    debug: kDebugMode,
    authOptions: FlutterAuthClientOptions(
      // 세션을 SharedPreferences 평문 대신 Keychain 에 저장한다.
      localStorage: const SecureSupabaseStorage(
        FlutterSecureStorage(
          // Android 기본값이 이미 AES-GCM + RSA OAEP 다 (fss 11.x).
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      ),
    ),
  );

  await configureDependencies();

  runApp(const DaylogApp());
}
