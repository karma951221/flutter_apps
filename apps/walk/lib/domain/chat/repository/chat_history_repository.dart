import '../entity/conversation.dart';

/// 물어보기 대화 기록. 보이는 질문 · 답만 저장한다.
abstract interface class ChatHistoryRepository {
  /// updatedAt 최근 순. 바뀔 때마다 다시 낸다.
  Stream<List<Conversation>> conversations();

  /// 그 대화가 있는 동안 true, 지워지면 false 를 낸다(중복 값은 내지 않는다).
  Stream<bool> watchExists(String id);

  Future<int> count();

  /// seq 오름차순. 없는 대화면 빈 목록.
  Future<List<ChatTurnRecord>> turns(String conversationId);

  /// [conversationId] 가 null 이면 대화 행을 새로 만들고(id = IdGenerator, title = conversationTitleFrom(question))
  /// 그 id 와 seq 1 을 돌려준다. 있으면 seq = max(seq)+1, updatedAt = now. 주어진 id 의 행이 없으면 StateError.
  /// askedAt · createdAt · updatedAt 은 Clock.now(). 한 트랜잭션.
  Future<ChatTurnRef> appendTurn({
    String? conversationId,
    required ChatTurnDraft turn,
  });

  /// trim 한 [title] 로 바꾸고 titleEdited = true. 빈 문자열이면 아무것도 안 한다. updatedAt 은 그대로.
  Future<void> rename(String id, String title);

  /// 턴 하나를 지운다. 남은 턴이 0 이면 대화도 지운다. titleEdited 가 아니고 지운 턴이 첫 턴이면
  /// 새 첫 턴의 질문으로 제목을 다시 만든다. updatedAt 은 그대로.
  Future<void> deleteTurn(String id, int seq);

  Future<void> delete(String id);

  /// 지운 대화 수. 사용량은 지우지 않는다.
  Future<int> deleteAll();

  /// updatedAt < [cutoff] 인 대화를 지운다. [except] 는 건너뛴다. 지운 수.
  Future<int> deleteOlderThan(DateTime cutoff, {String? except});
}
