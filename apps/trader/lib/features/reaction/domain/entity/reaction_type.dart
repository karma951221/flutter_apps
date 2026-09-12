/// 남길 수 있는 감정. `code` 는 DB 의 type CHECK 와 같은 문자열이어야 한다.
///
/// 감정을 추가할 때는 여기와 두 테이블의 CHECK 제약만 손대면 된다. 개수는
/// 컬럼이 아니라 jsonb 로 내려오므로 뷰는 고치지 않는다.
enum ReactionType {
  like('like'),
  dislike('dislike');

  const ReactionType(this.code);

  final String code;

  /// 모르는 코드는 null 이다. DB 에 감정을 먼저 추가하고 앱을 나중에 배포해도
  /// 목록이 깨지지 않도록, 호출부는 null 을 "표시하지 않음"으로 다룬다.
  static ReactionType? fromCode(String? code) {
    if (code == null) return null;
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}
