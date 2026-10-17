import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core/core.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'social_availability.dart';
import 'timeout_http_client.dart';

/// 소셜 요청 한 번의 시간 제한. 넘으면 네트워크 실패로 안내한다.
const socialRequestTimeout = Duration(seconds: 10);

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
///
/// 요청마다 [socialRequestTimeout] 시간 제한을 건다([TimeoutHttpClient]). postgrest 는
/// 읽기(GET)가 실패하면 스스로 다시 시도한다(기본 3번 + 1·2·4초 대기 → 최악 약 47초).
/// 다시 시도는 한 번만 해서 최악을 약 21초로 줄인다.
Future<SupabaseClient> connectSupabase() async {
  final supabase = await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    debug: kDebugMode,
    httpClient: TimeoutHttpClient(http.Client(), socialRequestTimeout),
    postgrestOptions: const PostgrestClientOptions(retryCount: 1),
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
