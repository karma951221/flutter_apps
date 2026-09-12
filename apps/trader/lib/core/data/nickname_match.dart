import 'like_pattern.dart';

/// 닉네임 중복 확인의 매칭 규칙.
///
/// DB 의 유일성 기준은 `profiles_nickname_lower_idx`, 즉 `lower(nickname)` 이다.
/// 앱의 사전 확인도 같은 기준이어야 하는데, 예전에는 `ilike(nickname, 값)` 하나로
/// 끝내고 있었다. 닉네임에는 길이(2–20) 말고 문자 제약이 없으므로 `%` · `_` ·
/// `*` 가 정상적인 닉네임 문자인데, `ilike` 는 그것들을 **와일드카드로** 해석한다.
///
/// 로컬 Supabase 로 확인한 실제 동작 (2026-08-27):
///
/// | 입력 | 결과 |
/// |---|---|
/// | `a_ice` | `alice` 한 건에 매칭 → 비어 있는 닉네임을 "이미 사용 중"으로 막았다 |
/// | `a%` · `a*` | 3건 매칭 → `PGRST116` → 확인이 조용히 실패했다 |
///
/// 그래서 두 단계로 나눈다 — DB 필터는 [LikePattern.escape] 로 좁히고,
/// 최종 판정은 [isSameNickname] 이 Dart 에서 정확히 한다. PostgREST 가 `*` 를
/// `%` 로 바꾸는 것만은 이스케이프로 막을 수 없어서 그 경우 필터가 넓게 걸리는데,
/// Dart 비교가 뒤에서 걸러내므로 결과는 옳다.
abstract final class NicknameMatch {
  /// 닉네임을 DB 필터에 끼워 넣을 수 있게 다듬는다.
  ///
  /// 이스케이프 규칙 자체는 채팅 방 검색도 같은 것을 쓰므로
  /// [LikePattern] 에 있다.
  static String escapeLikePattern(String value) => LikePattern.escape(value);

  /// `lower(nickname)` 유일 인덱스와 같은 기준으로 두 닉네임을 견준다.
  static bool isSameNickname(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// 넓게 걸린 후보를 가져올 상한.
  ///
  /// 이스케이프로 막지 못하는 `*` 때문에 필터가 넓어질 수 있다. 상한에 걸려
  /// 진짜 중복을 놓치면 "사용 가능"으로 보이지만, 저장은 유일 인덱스가 막는다 —
  /// 사전 확인의 실패 방향으로는 이쪽이 옳다(없는 중복을 만들어내지 않는다).
  static const candidateLimit = 50;
}
