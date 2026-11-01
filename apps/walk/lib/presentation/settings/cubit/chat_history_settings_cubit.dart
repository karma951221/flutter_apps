import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/chat/chat_history_settings.dart';
import '../../../domain/chat/repository/chat_history_repository.dart';
import '../../../domain/chat/repository/wiki_repository.dart';
import '../../../domain/chat/wiki/wiki_index.dart';
import 'chat_history_settings_state.dart';

/// 대화 보관 기간 · 대화 모두 지우기 · 위키 색인 크기 · 위키 모두 지우기.
/// 저장소 실패는 호출한 쪽(화면)으로 그대로 던진다.
class ChatHistorySettingsCubit extends Cubit<ChatHistorySettingsState> {
  ChatHistorySettingsCubit(this._settings, this._history, this._wiki)
    : super(const ChatHistorySettingsState());

  final ChatHistorySettings _settings;
  final ChatHistoryRepository _history;
  final WikiRepository _wiki;

  /// 보관 기간 · 대화 수 · 색인 크기 · 위키 수 · 색인 글자 수를 읽는다.
  /// 수를 못 읽으면 0 으로 둔다(모두 지우기 행이 꺼진다).
  Future<void> load() async {
    final retention = _settings.retention;
    final size = _settings.wikiIndexSize;
    var count = 0;
    try {
      count = await _history.count();
    } on Object {
      count = 0;
    }
    final (wikiCount, indexChars) = await _readWiki(size);
    if (isClosed) return;
    emit(
      state.copyWith(
        retention: retention,
        conversationCount: count,
        wikiIndexSize: size,
        wikiCount: wikiCount,
        wikiIndexChars: indexChars,
      ),
    );
  }

  Future<void> setRetention(ChatRetention value) async {
    await _settings.setRetention(value);
    if (isClosed) return;
    emit(state.copyWith(retention: value));
  }

  /// 저장 뒤 새 크기로 색인 글자 수를 다시 센다.
  Future<void> setWikiIndexSize(WikiIndexSize value) async {
    await _settings.setWikiIndexSize(value);
    if (isClosed) return;
    emit(state.copyWith(wikiIndexSize: value));
    final (wikiCount, indexChars) = await _readWiki(value);
    if (isClosed) return;
    emit(state.copyWith(wikiCount: wikiCount, wikiIndexChars: indexChars));
  }

  /// 지운 대화 수. 뒤에 대화 수를 다시 읽는다 — 다시 읽지 못하면 0 으로 둔다(지우기는 됐다).
  Future<int> deleteAllConversations() async {
    final deleted = await _history.deleteAll();
    int count;
    try {
      count = await _history.count();
    } on Object {
      count = 0;
    }
    if (!isClosed) emit(state.copyWith(conversationCount: count));
    return deleted;
  }

  /// 지운 메모 수. 뒤에 위키 수 · 색인 글자 수를 다시 읽는다(못 읽으면 0). 대화는 그대로.
  Future<int> deleteAllWiki() async {
    final deleted = await _wiki.deleteAll();
    final (wikiCount, indexChars) = await _readWiki(state.wikiIndexSize);
    if (!isClosed) {
      emit(state.copyWith(wikiCount: wikiCount, wikiIndexChars: indexChars));
    }
    return deleted;
  }

  /// (메모 수, [size] 로 만든 색인 글자 수). 읽지 못하면 (0, 0).
  Future<(int, int)> _readWiki(WikiIndexSize size) async {
    try {
      final notes = await _wiki.all();
      return (notes.length, buildWikiIndex(notes, size).chars);
    } on Object {
      return (0, 0);
    }
  }
}
