abstract final class TagName {
  static const maxLength = 30;

  /// 앞뒤 공백 · 앞의 '#'(여러 개) 제거, 모든 공백 제거, toLowerCase.
  /// 빈 문자열 · 30자(룬 기준) 초과면 null.
  static String? normalize(String raw) {
    final name = searchKey(raw);
    if (name.isEmpty || name.runes.length > maxLength) return null;
    return name;
  }

  /// [normalize] 와 같이 다듬되 길이를 검사하지 않는다. 검색 · 추천 입력용 —
  /// 빈 문자열이면 입력이 없는 것이고, 30자를 넘으면 어떤 태그와도 맞지 않는다.
  static String searchKey(String raw) => raw
      .trim()
      .replaceFirst(RegExp(r'^#+'), '')
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();
}
