import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// 환경 설정 — 트레이더 `AppConfig` 와 같은 모양(같은 Supabase 프로젝트 · 계정, plan 결정 1 · 8).
///
/// 값은 `--dart-define` 으로 주입한다. 주입이 없으면 로컬 Supabase 기본값을 쓴다.
/// 운영 환경 키는 저장소에 커밋하지 않는다.
abstract final class AppConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// 로컬 Supabase 주소.
  ///
  /// Android 에뮬레이터는 호스트를 127.0.0.1 로 볼 수 없다. 10.0.2.2 로 접근해야 한다.
  static String get supabaseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:54321';
    return 'http://127.0.0.1:54321';
  }

  /// publishable key 는 클라이언트에 노출되도록 설계된 공개 키다.
  /// 실제 보안은 RLS 정책이 담당한다. secret key 는 절대 앱에 넣지 않는다.
  static String get supabasePublishableKey =>
      _envKey.isNotEmpty ? _envKey : localPublishableKey;

  /// 로컬 Supabase 기본 키. 모든 로컬 설치에서 동일한 공개값이라 커밋해도 무해하다.
  static const localPublishableKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  static bool get isLocal => _envUrl.isEmpty;
}
