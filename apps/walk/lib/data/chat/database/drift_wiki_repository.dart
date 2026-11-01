import 'package:characters/characters.dart';
import 'package:core/core.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/chat/entity/wiki_note.dart';
import '../../../domain/chat/repository/wiki_repository.dart';
import 'chat_database.dart';

@LazySingleton(as: WikiRepository)
class DriftWikiRepository implements WikiRepository {
  DriftWikiRepository(this._db, this._clock);

  final ChatDatabase _db;
  final Clock _clock;

  SimpleSelectStatement<$WikiNotesTable, WikiNoteRow> _recentFirst() =>
      _db.select(_db.wikiNotes)..orderBy([
        (w) => OrderingTerm.desc(w.updatedAt),
        (w) => OrderingTerm.desc(w.id),
      ]);

  @override
  Stream<List<WikiNote>> notes() =>
      _recentFirst().watch().map((rows) => rows.map(_noteFrom).toList());

  @override
  Future<List<WikiNote>> all() async =>
      (await _recentFirst().get()).map(_noteFrom).toList();

  @override
  Stream<WikiNote?> watchNote(int id) =>
      (_db.select(_db.wikiNotes)..where((w) => w.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _noteFrom(r));

  @override
  Future<List<WikiNote>> byIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.wikiNotes,
    )..where((w) => w.id.isIn(ids))).get();
    final byId = {for (final r in rows) r.id: _noteFrom(r)};
    return [for (final id in ids) ?byId[id]];
  }

  @override
  Future<int> count() async {
    final n = _db.wikiNotes.id.count();
    final row = await (_db.selectOnly(
      _db.wikiNotes,
    )..addColumns([n])).getSingle();
    return row.read(n) ?? 0;
  }

  @override
  Future<int> create(WikiNoteDraft draft) async {
    final clean = _clean(draft);
    final now = _clock.now();
    return _db.transaction(
      () async => _db
          .into(_db.wikiNotes)
          .insert(
            WikiNotesCompanion.insert(
              title: clean.title,
              summary: clean.summary,
              body: clean.body,
              sourceConversationId: Value(
                await _liveSource(draft.sourceConversationId),
              ),
              createdAt: now,
              updatedAt: now,
            ),
          ),
    );
  }

  /// 출처 대화가 그새 지워졌으면 null — FK 로 저장이 실패하지 않게(대화를 지울 때와 같은 결과).
  Future<String?> _liveSource(String? id) async {
    if (id == null) return null;
    final row = await (_db.select(
      _db.conversations,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : id;
  }

  @override
  Future<void> update(int id, WikiNoteDraft draft) async {
    final clean = _clean(draft);
    final source = draft.sourceConversationId;
    final updated = await _db.transaction(
      () async =>
          (_db.update(_db.wikiNotes)..where((w) => w.id.equals(id))).write(
            WikiNotesCompanion(
              title: Value(clean.title),
              summary: Value(clean.summary),
              body: Value(clean.body),
              sourceConversationId: source == null
                  ? const Value.absent()
                  : Value(await _liveSource(source)),
              updatedAt: Value(_clock.now()),
            ),
          ),
    );
    if (updated == 0) {
      throw StateError('위키 메모 $id 가 없다');
    }
  }

  @override
  Future<void> delete(int id) =>
      (_db.delete(_db.wikiNotes)..where((w) => w.id.equals(id))).go();

  @override
  Future<int> deleteAll() => _db.delete(_db.wikiNotes).go();

  @override
  Future<List<WikiNote>> backlinks(int id) async {
    final target = WikiLink.note(id);
    final rows =
        await (_recentFirst()..where(
              (w) =>
                  w.body.like('%${wikiNoteLinkText(id)}%') &
                  w.id.equals(id).not(),
            ))
            .get();
    return [
      for (final r in rows)
        if (wikiLinksIn(r.body).contains(target)) _noteFrom(r),
    ];
  }

  WikiNote _noteFrom(WikiNoteRow r) => WikiNote(
    id: r.id,
    title: r.title,
    summary: r.summary,
    body: r.body,
    sourceConversationId: r.sourceConversationId,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}

final _whitespace = RegExp(r'\s+');

/// 저장 정리: 제목 · 요약은 trim(요약은 공백 묶음을 공백 하나로), 본문은 trim 만.
/// 각자 상한에서 grapheme 단위로 자른다. 제목이나 요약이 비면 ArgumentError.
({String title, String summary, String body}) _clean(WikiNoteDraft draft) {
  final title = _cut(draft.title.trim(), wikiTitleMax);
  final summary = _cut(
    draft.summary.replaceAll(_whitespace, ' ').trim(),
    wikiSummaryMax,
  );
  if (title.isEmpty) {
    throw ArgumentError.value('', 'title', '위키 메모 제목이 비었다');
  }
  if (summary.isEmpty) {
    throw ArgumentError.value('', 'summary', '위키 메모 요약이 비었다');
  }
  return (
    title: title,
    summary: summary,
    body: _cut(draft.body.trim(), wikiBodyMax),
  );
}

/// 상한에서 자르고, 자른 끝에 남은 공백을 지운다.
String _cut(String s, int max) {
  final chars = s.characters;
  return chars.length <= max ? s : chars.take(max).string.trimRight();
}
