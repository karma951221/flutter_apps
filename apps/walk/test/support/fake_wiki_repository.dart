import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/repository/wiki_repository.dart';

/// 위키 메모 하나. updatedAt 은 기본으로 id 가 클수록 최근.
WikiNote wikiNote(
  int id, {
  String? title,
  String? summary,
  String body = '',
  DateTime? updatedAt,
}) => WikiNote(
  id: id,
  title: title ?? '메모$id',
  summary: summary ?? '요약$id',
  body: body,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: updatedAt ?? DateTime(2026, 10, 1).add(Duration(minutes: id)),
);

/// 읽기만 하는 메모리 위키. [stored] 는 이미 최근 순이라고 본다.
class FakeWikiRepository implements WikiRepository {
  FakeWikiRepository([List<WikiNote> notes = const []]) : stored = [...notes];

  List<WikiNote> stored;
  int allCalls = 0;
  final List<List<int>> byIdsCalls = [];

  @override
  Future<List<WikiNote>> all() async {
    allCalls++;
    return [...stored];
  }

  @override
  Future<List<WikiNote>> byIds(List<int> ids) async {
    byIdsCalls.add([...ids]);
    final byId = {for (final n in stored) n.id: n};
    return [for (final id in ids) ?byId[id]];
  }

  @override
  Future<int> count() async => stored.length;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
