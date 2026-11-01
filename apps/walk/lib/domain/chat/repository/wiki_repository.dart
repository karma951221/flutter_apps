import '../entity/wiki_note.dart';

/// 물어보기 위키 메모(D5). 대화 기록과 같은 chat DB 에 있다.
abstract interface class WikiRepository {
  /// updatedAt 최근 순(같으면 id 큰 순). 바뀔 때마다 다시 낸다.
  Stream<List<WikiNote>> notes();

  /// 한 번 읽기 — 색인 · 정리 요청용. notes() 와 같은 순서.
  Future<List<WikiNote>> all();

  Stream<WikiNote?> watchNote(int id);

  /// 있는 것만, [ids] 순서 유지.
  Future<List<WikiNote>> byIds(List<int> ids);

  Future<int> count();

  /// 새 id. createdAt = updatedAt = now.
  Future<int> create(WikiNoteDraft draft);

  /// updatedAt = now. sourceConversationId 는 draft 가 null 이면 기존 값을 둔다. 없는 id 면 StateError.
  Future<void> update(int id, WikiNoteDraft draft);

  Future<void> delete(int id);

  /// 지운 수. 대화 · 사용량은 지우지 않는다.
  Future<int> deleteAll();

  /// 본문에 [[id]] 가 든 메모(자기 자신 제외), updatedAt 최근 순.
  Future<List<WikiNote>> backlinks(int id);
}
