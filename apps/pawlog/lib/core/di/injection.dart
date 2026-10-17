import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../supabase/social_availability.dart';
import 'injection.config.dart';

/// [social] 은 bootstrap 이 Supabase 초기화 결과로 넘긴다. 기본값(쓸 수 없음)은
/// Supabase 없이 DI 만 확인하는 테스트용이다.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  externalPackageModulesBefore: [ExternalModule(CorePackageModule)],
  // init 전에 손으로 넣는다 — 초기화 결과라 생성 코드가 만들 수 없다.
  ignoreUnregisteredTypes: [SocialAvailability],
)
Future<void> configureDependencies({
  SocialAvailability social = const SocialAvailability.unavailable(),
}) async {
  getIt.registerSingleton<SocialAvailability>(social);
  await getIt.init();
}
