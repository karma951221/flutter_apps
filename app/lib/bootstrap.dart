import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
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
  await initializeApp();
  runApp(const DaylogApp());
}

/// runApp 직전까지의 준비 단계.
///
/// E2E 테스트는 자기 손으로 위젯을 pump 해야 하므로 [runApp] 을 부를 수 없다.
/// 그래서 준비 단계만 여기로 떼어내 테스트와 공유한다.
/// Supabase 는 프로세스당 한 번만 초기화할 수 있어서 [_supabaseReady] 로 막는다.
Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO(0단계 이후): 크래시 리포팅 연결
  };

  if (_supabaseReady) {
    await configureDependencies();
    return;
  }

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

  _supabaseReady = true;

  await configureDependencies();
}

bool _supabaseReady = false;
