import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // @preResolve 로 등록한 인스턴스(SharedPreferences)가 준비될 때까지 기다린다.
  // 기다리지 않으면 첫 화면이 아직 없는 인스턴스를 찾는다.
  await getIt.init();
}
