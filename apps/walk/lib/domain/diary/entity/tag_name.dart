abstract final class TagName {
  static const maxLength = 30;

  /// 앞뒤 공백 · 앞의 '#'(여러 개) 제거, 모든 공백 제거, toLowerCase.
  /// 빈 문자열 · 30자(룬 기준) 초과면 null.
  static String? normalize(String raw) {
    final name = raw
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    if (name.isEmpty || name.runes.length > maxLength) return null;
    return name;
  }
}
