import 'package:core/core.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_reaction/feature_reaction.dart';
import 'package:feature_safety/feature_safety.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(FeatureAuthPackageModule),
    ExternalModule(FeatureSafetyPackageModule),
    ExternalModule(FeatureReactionPackageModule),
  ],
)
Future<void> configureDependencies() async {
  // @preResolve 로 등록한 인스턴스(SharedPreferences)가 준비될 때까지 기다린다.
  // 기다리지 않으면 첫 화면이 아직 없는 인스턴스를 찾는다.
  await getIt.init();
}
