import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/app_info/app_info_source.dart';

@LazySingleton(as: AppInfoSource)
class PackageInfoAppInfoSource implements AppInfoSource {
  @override
  Future<String> version() async {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';
  }
}
