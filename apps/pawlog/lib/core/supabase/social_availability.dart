import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 를 쓸 수 있는지 — 모두의 산책 · 로그인의 스위치.
///
/// 로컬 우선 앱이라 Supabase 초기화가 실패해도 앱은 뜬다(plan 결정 8). 그때는
/// [client] 가 null 이고, `RegisterModule` 은 SupabaseClient 를 쓰는 저장소 대신
/// "쓸 수 없음" 저장소를 등록한다. `SupabaseClient` 를 getIt 에 직접 등록하지 않는
/// 이유가 이것이다 — 등록이 없으면 처음 꺼내는 곳에서 앱이 죽는다.
///
/// `configureDependencies` 가 `getIt.init()` 전에 싱글턴으로 넣는다.
class SocialAvailability {
  const SocialAvailability.available(SupabaseClient this.client);

  const SocialAvailability.unavailable() : client = null;

  /// 초기화된 클라이언트. 실패했으면 null.
  final SupabaseClient? client;

  bool get isAvailable => client != null;
}
