import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

  @lazySingleton
  Uuid get uuid => const Uuid();

  /// DI 준비 중에 미리 받아 둔다(`@preResolve`). 인스턴스가 손에 있으면 값 읽기가
  /// 동기라, 첫 프레임부터 저장된 테마로 뜬다 — 라이트로 떴다가 다크로 바뀌는
  /// 깜빡임이 없다.
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
