import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 서드파티 인스턴스 등록.
///
/// 직접 소유하지 않는 클래스(어노테이션을 달 수 없는 것)는 여기서 등록한다.
@module
abstract class RegisterModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Supabase.initialize() 는 bootstrap 에서 이미 끝난 상태다.
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
