/// 계정 단위 조회의 원천. 세션이 없으면 null 을 돌려준다 — 판정은 repository 가 한다.
abstract interface class AccountDataSource {
  Future<({int postCount, int commentCount})?> myContentSummary();
}
