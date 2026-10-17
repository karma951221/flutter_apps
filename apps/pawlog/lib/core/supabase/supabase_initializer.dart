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

/// 사용자가 기다리는 소셜 동작 하나(목록 읽기 · 공유 · 좋아요)의 전체 시간 제한.
/// 요청 앞에 세션 갱신이 붙어도 이 안에 오류를 보인다.
const socialCallDeadline = Duration(seconds: 12);

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
/// 요청마다 [socialRequestTimeout] 시간 제한을 건다([TimeoutHttpClient]). postgrest 의 읽기
/// 재시도는 끈다. 다만 `client.from(...)` 은 이 설정을 넘기지 않으므로(supabase 2.16.1)
/// 게이트웨이가 요청마다 `retry(enabled: false)` 를 건다. 동작 하나의 전체 제한은
/// [socialCallDeadline] — 저장소가 건다.
Future<SupabaseClient> connectSupabase() async {
  final supabase = await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
    debug: kDebugMode,
    httpClient: TimeoutHttpClient(http.Client(), socialRequestTimeout),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
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
