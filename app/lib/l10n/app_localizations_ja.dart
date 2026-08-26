// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsProfileEdit => 'プロフィール編集';

  @override
  String get settingsAccount => 'アカウント設定';

  @override
  String get settingsTheme => '画面テーマ';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsBlockedUsers => 'ブロックしたユーザー';

  @override
  String get settingsSignOut => 'ログアウト';

  @override
  String get settingsSignOutConfirmTitle => 'ログアウトしますか？';

  @override
  String get settingsSignOutConfirmMessage => '再び利用するにはログインが必要です。';

  @override
  String get themeModeSystem => 'システム設定';

  @override
  String get themeModeLight => 'ライト';

  @override
  String get themeModeDark => 'ダーク';

  @override
  String get languageSystem => 'システム設定';
}
