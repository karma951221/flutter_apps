import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 직접 소유하지 않는 인스턴스 등록.
@module
abstract class RegisterModule {
  /// DI 준비 중에 미리 받아 둔다(`@preResolve`). 값 읽기가 동기가 되어
  /// 첫 프레임부터 저장된 테마로 뜬다.
  @preResolve
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();
}
