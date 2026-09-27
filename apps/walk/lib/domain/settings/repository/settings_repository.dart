import '../entity/app_settings.dart';

abstract interface class SettingsRepository {
  /// 동기다 — 저장소가 DI 준비 때 미리 열려 있어, 첫 프레임부터 저장된 테마로 뜬다.
  AppSettings load();

  Future<void> save(AppSettings settings);
}
