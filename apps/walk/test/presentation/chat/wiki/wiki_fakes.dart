import 'dart:async';

import 'package:core/core.dart';
import 'package:walk/domain/chat/attachment/attachment_rules.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/repository/wiki_repository.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';

/// 메모리 위의 위키. 목록 · 메모 하나 구독 · 지우기 · 역링크를 쓴다.
/// [stored] 는 이미 최근 순이라고 본다.
class MemoryWikiRepository implements WikiRepository {
  MemoryWikiRepository([List<WikiNote> notes = const []]) : stored = [...notes];

  List<WikiNote> stored;
  final _changes = StreamController<void>.broadcast();

  /// 설정하면 create · update · delete · deleteAll 이 던진다.
  bool failWrites = false;

  /// 설정하면 목록 스트림이 첫 값 대신 오류를 낸다.
  bool failList = false;

  int deleteAllCalls = 0;
  final List<int> deleted = [];

  /// 바뀐 것을 구독자에게 알린다(테스트가 [stored] 를 직접 바꾼 뒤에도 부른다).
  void changed() => _changes.add(null);

  /// 구독하면 지금 값을 내고, [changed] 마다 [read] 를 다시 낸다. 취소하면 바로 끝난다.
  Stream<T> _watch<T>(T Function() read, {bool fail = false}) {
    StreamSubscription<void>? sub;
    late final StreamController<T> out;
    out = StreamController<T>(
      onListen: () {
        if (fail) {
          out.addError(StateError('db'));
          return;
        }
        out.add(read());
        sub = _changes.stream.listen((_) => out.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Stream<List<WikiNote>> notes() =>
      _watch(() => List<WikiNote>.unmodifiable(stored), fail: failList);

  WikiNote? _find(int id) {
    for (final n in stored) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  Stream<WikiNote?> watchNote(int id) => _watch(() => _find(id));

  @override
  Future<List<WikiNote>> all() async => [...stored];

  @override
  Future<List<WikiNote>> byIds(List<int> ids) async => [
    for (final id in ids) ?_find(id),
  ];

  @override
  Future<int> count() async => stored.length;

  /// create · update 에 넘어온 내용(순서대로).
  final List<WikiNoteDraft> created = [];
  final List<(int, WikiNoteDraft)> updated = [];

  /// 새 메모 id 는 지금 가장 큰 id + 1.
  @override
  Future<int> create(WikiNoteDraft draft) async {
    if (failWrites) throw StateError('db');
    created.add(draft);
    final id =
        [for (final n in stored) n.id].fold(0, (a, b) => a > b ? a : b) + 1;
    final now = DateTime(2026, 11, 2, 9);
    stored = [
      WikiNote(
        id: id,
        title: draft.title,
        summary: draft.summary,
        body: draft.body,
        sourceConversationId: draft.sourceConversationId,
        createdAt: now,
        updatedAt: now,
      ),
      ...stored,
    ];
    changed();
    return id;
  }

  @override
  Future<void> update(int id, WikiNoteDraft draft) async {
    if (failWrites) throw StateError('db');
    final old = _find(id);
    if (old == null) throw StateError('no note $id');
    updated.add((id, draft));
    stored = [
      old.copyWith(
        title: draft.title,
        summary: draft.summary,
        body: draft.body,
        sourceConversationId:
            draft.sourceConversationId ?? old.sourceConversationId,
      ),
      for (final n in stored)
        if (n.id != id) n,
    ];
    changed();
  }

  @override
  Future<void> delete(int id) async {
    if (failWrites) throw StateError('db');
    deleted.add(id);
    stored.removeWhere((n) => n.id == id);
    changed();
  }

  @override
  Future<int> deleteAll() async {
    deleteAllCalls++;
    if (failWrites) throw StateError('db');
    final n = stored.length;
    stored = [];
    changed();
    return n;
  }

  @override
  Future<List<WikiNote>> backlinks(int id) async => [
    for (final n in stored)
      if (n.id != id && wikiLinksIn(n.body).contains(WikiLink.note(id))) n,
  ];

  Future<void> close() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 기록 하나 읽기 · 기간 찾기만 하는 일기 저장소. 없는 id 는 notFound.
class EntryOnlyDiary implements DiaryRepository {
  EntryOnlyDiary([List<DiaryEntry> entries = const []])
    : entries = {for (final e in entries) e.id: e};

  final Map<String, DiaryEntry> entries;

  /// searchEntries 에 넘어온 (from, to).
  final List<(DateTime, DateTime)> searches = [];

  @override
  Future<Result<DiaryEntry>> entry(String id) async => switch (entries[id]) {
    final e? => Ok(e),
    null => const Err(Failure.notFound()),
  };

  /// 양 끝 포함, 휴지통 제외, occurredAt 오름차순. 다른 조건은 보지 않는다.
  @override
  Future<List<DiaryEntry>> searchEntries({
    required DateTime from,
    required DateTime to,
    String? query,
    String? tag,
    String? place,
    String? storyId,
    int limit = 50,
  }) async {
    searches.add((from, to));
    return [
      for (final e in entries.values)
        if (e.deletedAt == null &&
            !e.occurredAt.isBefore(from) &&
            !e.occurredAt.isAfter(to))
          e,
    ]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 대화가 있는지 · 그 턴들만 답하는 대화 저장소.
class ExistsOnlyHistory implements ChatHistoryRepository {
  ExistsOnlyHistory([Set<String> ids = const {}, this.turnsById = const {}])
    : ids = {...ids};

  final Set<String> ids;
  final Map<String, List<ChatTurnRecord>> turnsById;

  @override
  Stream<bool> watchExists(String id) => Stream.value(ids.contains(id));

  @override
  Future<List<ChatTurnRecord>> turns(String conversationId) async =>
      turnsById[conversationId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// target 만 답하는 세션.
class TargetOnlySession implements ChatSession {
  TargetOnlySession(this.target);

  @override
  final ChatTarget? target;

  @override
  ({int images, int docs, int docBytes}) get attachmentRoom => (
    images: 12,
    docs: 5,
    docBytes: AttachmentRules.maxDocBytesPerConversation,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const claudeTarget = (vendor: ChatVendor.anthropic, model: 'claude-x');

/// 위키 테스트의 일기 기록. [trashed] 면 휴지통.
DiaryEntry wikiEntry(
  String id, {
  String body = '한강을 따라 오래 걸었다',
  DateTime? occurredAt,
  bool trashed = false,
}) {
  final at = occurredAt ?? DateTime(2026, 10, 3, 9);
  return DiaryEntry(
    id: id,
    storyId: 's1',
    body: body,
    occurredAt: at,
    createdAt: at,
    updatedAt: at,
    deletedAt: trashed ? at : null,
    media: const [],
    tags: const [],
  );
}
