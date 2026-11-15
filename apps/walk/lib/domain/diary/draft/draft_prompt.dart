import 'package:intl/intl.dart';

import 'draft_context.dart';
import 'draft_length.dart';
import 'draft_style.dart';
import 'photo_meta.dart';

/// 초안 요청의 system · user 글(스펙 §4 모델에 보내는 것). 순수 함수.
///
/// user 글에는 [DraftContext] 의 값만 — 좌표는 [DraftContext] 에 없어 실릴 수 없다.
abstract final class DraftPrompt {
  static const _base =
      '너는 사용자의 개인 기록 앱 Life Tool 의 일기 초안 도우미다.\n'
      '아래 메모와 맥락으로 사용자가 직접 쓴 것 같은 개인 일기 글을 1인칭으로 쓴다. '
      '메모와 맥락에 없는 사실(사람 · 장소 · 음식 · 감정 · 날씨)을 지어내지 않는다. '
      '제목 · 따옴표 · 설명 없이 글만 돌려준다.';

  static String system({
    required DraftStyle style,
    required DraftLength length,
    bool withPhotos = false,
    bool polish = false,
    String memo = '',
    String? locale,
  }) {
    final lines = [
      _base,
      if (memo.trim().isNotEmpty)
        '언어: 메모와 같은 언어로 쓴다.'
      else
        '언어: ${_languageName(locale)}로 쓴다.',
      if (polish) '지금 글을 다듬는다 — 새 사실을 더하지 말고 문장만 자연스럽게 고친다.',
      '길이: ${length.min}~${length.max}문장.',
      if (length.polishMemo) '메모가 길다 — 새 문장을 덧붙이기보다 메모를 자연스럽게 다듬는다.',
      if (withPhotos) '붙인 사진은 글의 재료로만 쓰고, 사진에 분명히 보이는 것만 적는다.',
      style.instruction,
    ];
    return lines.join('\n');
  }

  static String user(DraftContext context) {
    final memo = context.memo.trim();
    final place = _omitsPlace(context) ? '' : context.placeName?.trim() ?? '';
    final tags = [
      for (final tag in context.tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    final counts = [
      if (context.photoCount > 0) '사진 ${context.photoCount}장',
      if (context.videoCount > 0) '영상 ${context.videoCount}개',
    ];
    final taken = _takenRange(context.photoTakenFrom, context.photoTakenTo);
    final lines = [
      if (memo.isNotEmpty) '메모: $memo',
      '기록 시각: ${_minute.format(context.occurredAt)}',
      if (place.isNotEmpty) '장소: $place',
      if (counts.isNotEmpty) counts.join(' · '),
      if (taken != null) '사진 촬영 시각: $taken',
      if (tags.isNotEmpty) '태그: ${tags.join(', ')}',
    ];
    return '${lines.join('\n')}\n';
  }

  /// 자동으로 잡힌 현재 위치인데 사진은 지금과 먼 때 찍었다 — 사진 속 장소가 아닐 수 있다(R-A6).
  static bool _omitsPlace(DraftContext context) {
    final taken = context.photoTakenFrom;
    final now = context.now;
    return context.autoPlace &&
        taken != null &&
        now != null &&
        takenFarFromNow(taken, now);
  }

  /// 앱 언어 코드 → 지시에 쓸 이름. 모르는 코드는 그대로 보인다.
  static String _languageName(String? locale) =>
      switch (locale?.split(RegExp('[_-]')).first) {
        null || 'ko' => '한국어',
        'en' => '영어(English)',
        'ja' => '일본어(日本語)',
        final code => "언어 코드 '$code' 의 언어",
      };

  static final _minute = DateFormat('yyyy-MM-dd HH:mm');
  static final _time = DateFormat('HH:mm');

  static String? _takenRange(DateTime? from, DateTime? to) {
    if (from == null && to == null) return null;
    final start = from ?? to!;
    final end = to ?? start;
    if (start == end) return _minute.format(start);
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return '${_minute.format(start)} ~ '
        '${sameDay ? _time.format(end) : _minute.format(end)}';
  }
}
