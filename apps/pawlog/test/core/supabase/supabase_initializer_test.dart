import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/core/supabase/social_availability.dart';
import 'package:pawlog/core/supabase/supabase_initializer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('초기화가 성공하면 클라이언트를 담은 available 을 돌려준다', () async {
    final client = SupabaseClient('http://127.0.0.1:54321', 'key');
    addTearDown(client.dispose);

    final availability = await initializeSupabase(connect: () async => client);

    expect(availability.isAvailable, isTrue);
    expect(availability.client, same(client));
  });

  test('초기화가 던져도 앱은 계속 뜬다 — unavailable 을 돌려준다', () async {
    final availability = await initializeSupabase(
      connect: () async => throw Exception('no network'),
    );

    expect(availability.isAvailable, isFalse);
    expect(availability.client, isNull);
  });

  test('unavailable 은 기본값으로 쓸 수 있다', () {
    const availability = SocialAvailability.unavailable();

    expect(availability.isAvailable, isFalse);
  });
}
