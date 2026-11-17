import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/chat/suggest/chat_suggestion_store.dart';
import '../../domain/chat/suggest/chat_suggestions.dart';

/// 추천은 JSON 문자열 하나, 시도 시각은 ISO 문자열로 둔다. 모양이 다르면 없는 것으로 본다.
@LazySingleton(as: ChatSuggestionStore)
class PrefsChatSuggestionStore implements ChatSuggestionStore {
  PrefsChatSuggestionStore(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'walk.chat.suggestions';
  static const triedAtKey = 'walk.chat.suggestionsTriedAt';

  String? _string(String k) => switch (_prefs.get(k)) {
    final String value => value,
    _ => null,
  };

  @override
  ChatSuggestions? get current {
    final raw = _string(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, Object?>) return null;
      final questions = map['questions'];
      final generatedAt = _dateOf(map['generatedAt']);
      final basedOn = _dateOf(map['basedOnAskedAt']);
      if (questions is! List ||
          questions.isEmpty ||
          questions.any((q) => q is! String) ||
          generatedAt == null ||
          basedOn == null) {
        return null;
      }
      return ChatSuggestions(
        questions: List.unmodifiable(questions.cast<String>()),
        generatedAt: generatedAt,
        basedOnAskedAt: basedOn,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(ChatSuggestions value) => _prefs.setString(
    key,
    jsonEncode({
      'questions': value.questions,
      'generatedAt': value.generatedAt.toIso8601String(),
      'basedOnAskedAt': value.basedOnAskedAt.toIso8601String(),
    }),
  );

  @override
  DateTime? get triedAt => _dateOf(_string(triedAtKey));

  @override
  Future<void> setTriedAt(DateTime value) =>
      _prefs.setString(triedAtKey, value.toIso8601String());

  static DateTime? _dateOf(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
