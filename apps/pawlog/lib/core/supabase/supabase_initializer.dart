import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'social_availability.dart';

/// Supabase 를 초기화한다. 실패해도 던지지 않고 [SocialAvailability.unavailable] 을 돌려준다.
///
/// [connect] 는 테스트가 실패를 흉내 내려고 바꾼다. 기본값은 [connectSupabase].
Future<SocialAvailability> initializeSupabase({
  Future<SupabaseClient> Function() connect = connectSupabase,
}) async {
  try {
    return SocialAvailability.available(await connect());
  } catch (error) {
    // 로컬 기록 · 산책은 서버와 무관하다. 모두의 산책만 오류 안내를 보인다.
    debugPrint('supabase init failed: $error');
    return const SocialAvailability.unavailable();
  }
}

/// 트레이더 `initializeApp` 과 같은 설정 — 세션은 SharedPreferences 평문 대신
/// Keychain · Keystore 에 둔다.
Future<SupabaseClient> connectSupabase() async {
  final supabase = await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    debug: kDebugMode,
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureSupabaseStorage(
        FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      ),
    ),
  );
  return supabase.client;
}
