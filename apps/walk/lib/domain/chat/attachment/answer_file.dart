/// 답 하나를 작업 폴더 out/ 에 남기는 `.md` 파일의 이름과 내용.
/// 순수 도메인 코드 — 시각은 받은 값 그대로(지역 시간) 적는다.
abstract final class AnswerFile {
  static const _slugLength = 20;
  static const _fallback = '답';

  /// 파일 이름에 못 쓰는 글자(경로 구분자 · 윈도 금지 글자 · 제어 문자).
  static final _forbidden = RegExp(r'[\\/:*?"<>|\x00-\x1f]');

  /// `YYYYMMDD-HHmm-<슬러그>.md`. 슬러그는 질문 첫 줄 앞 20자.
  static String fileName(DateTime at, String question) {
    final slug = _slug(_firstLine(question));
    return '${_two4(at.year)}${_two(at.month)}${_two(at.day)}-${_hm(at)}-'
        '${slug.isEmpty ? _fallback : slug}.md';
  }

  /// `# 첫 줄` · 날짜 · 모델 · (첨부) · `---` · 답.
  static String markdown({
    required String question,
    required String answer,
    required String model,
    required DateTime at,
    required List<String> attachmentNames,
  }) {
    final title = _firstLine(question);
    final date = '${_two4(at.year)}-${_two(at.month)}-${_two(at.day)}';
    final buffer = StringBuffer()
      ..writeln('# ${title.isEmpty ? _fallback : title}')
      ..writeln()
      ..writeln('- 날짜: $date ${_hm(at, ':')}')
      ..writeln('- 모델: $model');
    if (attachmentNames.isNotEmpty) {
      buffer.writeln('- 첨부: ${attachmentNames.join(', ')}');
    }
    buffer
      ..writeln()
      ..writeln('---')
      ..writeln()
      ..writeln(answer);
    return buffer.toString();
  }

  static String _firstLine(String text) {
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String _slug(String line) {
    final head = String.fromCharCodes(line.runes.take(_slugLength));
    return head
        .replaceAll(_forbidden, '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _two4(int n) => n.toString().padLeft(4, '0');

  static String _hm(DateTime at, [String sep = '']) =>
      '${_two(at.hour)}$sep${_two(at.minute)}';
}
