import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 설정 탭 "앱 정보"의 버전.
abstract interface class AppInfoSource {
  /// `1.0.0 (1)` 형식 — pubspec 의 `version: 1.0.0+1`.
  Future<String> version();
}

@LazySingleton(as: AppInfoSource)
class PackageInfoAppInfoSource implements AppInfoSource {
  @override
  Future<String> version() async {
    final info = await PackageInfo.fromPlatform();
    return info.buildNumber.isEmpty ? info.version : '${info.version} (${info.buildNumber})';
  }
}
