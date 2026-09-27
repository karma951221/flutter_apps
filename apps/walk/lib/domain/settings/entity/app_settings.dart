import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// 화면 테마 선택. Flutter `ThemeMode` 와 같은 뜻이지만 domain 이 Flutter 에 기대지 않게 따로 둔다.
enum AppThemeMode { system, light, dark }

@freezed
class AppSettings with _$AppSettings {
  @override
  final AppThemeMode themeMode;

  const AppSettings({this.themeMode = AppThemeMode.system});
}
