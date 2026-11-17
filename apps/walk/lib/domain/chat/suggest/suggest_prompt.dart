import 'package:intl/intl.dart';

import '../entity/conversation.dart';

/// 추천 질문 요청의 system · user 글과 답 파싱(스펙 2026-11-17 §3). 순수 함수.
///
/// user 글에는 질문 글 · 물은 날짜 · 오늘 날짜만 — 답 · 기록 · 첨부는 싣지 않는다.
abstract final class SuggestPrompt {
  /// 추천 질문 수.
  static const count = 4;

  /// 추천 질문 한 개의 최대 길이(글자).
  static const maxLength = 40;

  /// 보내는 질문 한 개의 최대 길이(글자).
  static const maxQuestionLength = 200;

  static String system(String? locale) => [
    '너는 개인 기록 앱 Life Log 의 "물어보기" 화면에 띄울 추천 질문을 만든다.',
    '이 앱은 사용자의 일기 · 걷기 · 위치 · 알람 기록을 찾아 답하고, 일반 질문에도 답한다.',
    '사용자의 최근 질문을 보고 관심사를 짐작해, 사용자가 다음에 눌러 볼 만한 질문 $count개를 만든다.',
    '최근 질문을 그대로 베끼지 말고, 비슷한 관심사를 다른 기간 · 다른 각도로 묻는다.',
    '사용자가 직접 묻는 1인칭 말투로, 질문 하나는 $maxLength자 이하로 짧게 쓴다.',
    '언어: ${_languageName(locale)}로 쓴다.',
    '한 줄에 질문 하나씩, 번호 · 기호 · 설명 없이 질문만 돌려준다.',
  ].join('\n');

  static String user(List<RecentQuestion> recent, DateTime today) {
    final lines = [
      '오늘: ${_day.format(today)} (${_weekdays[today.weekday - 1]})',
      '최근 질문(최근 순):',
      for (final q in recent)
        '- [${_day.format(q.askedAt)}] ${_clip(q.question)}',
    ];
    return '${lines.join('\n')}\n';
  }

  /// 모델 답 → 질문 목록. 번호 · 글머리표 · 따옴표를 떼고, 빈 줄 · [maxLength] 초과 · 중복을 빼고
  /// 앞 [count] 개.
  static List<String> parse(String text) {
    final result = <String>[];
    for (final line in text.split('\n')) {
      final q = line
          .trim()
          .replaceFirst(_marker, '')
          .trim()
          .replaceAll(_quotes, '')
          .trim();
      if (q.isEmpty || q.length > maxLength || result.contains(q)) continue;
      result.add(q);
      if (result.length == count) break;
    }
    return result;
  }

  static final _marker = RegExp(r'^(?:\d+[.)]|[-*•·])\s*');
  static final _quotes = RegExp('^["“”\'‘’]+|["“”\'‘’]+\$');
  static final _day = DateFormat('yyyy-MM-dd');
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static String _clip(String question) {
    final flat = question.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= maxQuestionLength
        ? flat
        : flat.substring(0, maxQuestionLength);
  }

  static String _languageName(String? locale) =>
      switch (locale?.split(RegExp('[_-]')).first) {
        null || 'ko' => '한국어',
        'en' => '영어(English)',
        'ja' => '일본어(日本語)',
        final code => "언어 코드 '$code' 의 언어",
      };
}
