import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/chat_history_settings.dart';

/// 값은 enum 이름 문자열(내 기록 참고만 bool)로 둔다. 타입이 다르거나 모르는 이름이면 기본값.
@LazySingleton(as: ChatHistorySettings)
class PrefsChatHistorySettings implements ChatHistorySettings {
  PrefsChatHistorySettings(this._prefs);

  final SharedPreferences _prefs;

  static const retentionKey = 'walk.chat.retention';
  static const wikiIndexSizeKey = 'walk.chat.wikiIndexSize';
  static const useRecordsKey = 'walk.chat.useRecords';

  // getString 은 문자열이 아닌 값에서 던지므로 get 으로 읽고 타입을 확인한다.
  String? _string(String key) => switch (_prefs.get(key)) {
    final String value => value,
    _ => null,
  };

  @override
  ChatRetention get retention =>
      ChatRetention.values.asNameMap()[_string(retentionKey)] ??
      ChatRetention.fallback;

  @override
  Future<void> setRetention(ChatRetention value) =>
      _prefs.setString(retentionKey, value.name);

  @override
  WikiIndexSize get wikiIndexSize =>
      WikiIndexSize.values.asNameMap()[_string(wikiIndexSizeKey)] ??
      WikiIndexSize.fallback;

  @override
  Future<void> setWikiIndexSize(WikiIndexSize value) =>
      _prefs.setString(wikiIndexSizeKey, value.name);

  /// 없거나 bool 이 아니면 켬.
  @override
  bool get useRecords => switch (_prefs.get(useRecordsKey)) {
    final bool value => value,
    _ => true,
  };

  @override
  Future<void> setUseRecords(bool value) =>
      _prefs.setBool(useRecordsKey, value);
}
