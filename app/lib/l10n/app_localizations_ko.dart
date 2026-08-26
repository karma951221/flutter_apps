// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonCancel => '취소';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsProfileEdit => '프로필 편집';

  @override
  String get settingsAccount => '계정 설정';

  @override
  String get settingsTheme => '화면 테마';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsBlockedUsers => '차단한 사용자';

  @override
  String get settingsSignOut => '로그아웃';

  @override
  String get settingsSignOutConfirmTitle => '로그아웃할까요?';

  @override
  String get settingsSignOutConfirmMessage => '다시 사용하려면 로그인해야 합니다.';

  @override
  String get themeModeSystem => '시스템 설정';

  @override
  String get themeModeLight => '라이트';

  @override
  String get themeModeDark => '다크';

  @override
  String get languageSystem => '시스템 설정';
}
