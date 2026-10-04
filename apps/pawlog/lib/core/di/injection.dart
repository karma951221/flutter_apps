import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
  externalPackageModulesBefore: [ExternalModule(CorePackageModule)],
)
Future<void> configureDependencies() async {
  await getIt.init();
}
