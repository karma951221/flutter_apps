import 'dart:convert';

import 'package:intl/intl.dart';

import '../entity/entry_draft.dart';
import '../entity/story.dart';
import 'story_pick.dart';

/// 프롬프트에 싣는 열린 스토리 하나 — 이름과 최근 기록 몇 개의 앞부분.
final class StoryCandidate {
  const StoryCandidate({required this.story, this.samples = const []});

  final Story story;

  /// 최근 기록 본문(최신순). 프롬프트에서 [StoryClassifyPrompt.maxSampleLength] 로 자른다.
  final List<String> samples;
}

/// 스토리 고르기 요청의 system · user 글과 답 파싱(스펙 2026-11-19). 순수 함수.
///
/// 답은 JSON 한 개: 기존이면 `{"story_id": "...", "reason": "..."}`,
/// 새 스토리면 `{"new_story": "이름", "reason": "..."}`.
abstract final class StoryClassifyPrompt {
  /// 새 스토리 이름의 최대 길이(글자). 넘으면 자른다.
  static const maxTitleLength = 30;

  /// 이유의 최대 길이(글자). 넘으면 자른다.
  static const maxReasonLength = 80;

  /// 보내는 본문의 최대 길이(글자).
  static const maxBodyLength = 1500;

  /// 스토리 하나에 싣는 최근 기록 본문의 최대 길이(글자).
  static const maxSampleLength = 100;

  static String system(String? locale) => [
    '너는 개인 일기 앱 Life Log 에서 새 일기를 어느 "스토리"에 넣을지 고른다.',
    '스토리는 일기를 묶는 분류다(여행 · 프로젝트 · 운동 · 시기 같은 주제). "일상"은 기본 스토리로, '
        '특정 주제에 속하지 않는 평범한 하루 기록이 들어간다.',
    '규칙:',
    '1. 주어진 스토리 중 이 일기와 주제가 맞는 것이 있으면 그 스토리를 고른다. 이름과 최근 기록을 보고 판단한다.',
    '2. 맞는 스토리가 없고, 이 일기가 앞으로도 이어질 뚜렷한 주제(여행 · 새 취미 · 프로젝트 등)를 시작하는 것 같으면 '
        '새 스토리를 제안한다. 이름은 짧은 명사구로, $maxTitleLength자 이하.',
    '3. 그 밖의 평범한 하루 기록은 "일상"을 고른다. 새 스토리는 꼭 필요할 때만 제안한다.',
    '이유는 사용자에게 보일 한 문장으로, $maxReasonLength자 이하.',
    '언어: 새 스토리 이름과 이유는 ${_languageName(locale)}로 쓴다.',
    '답은 JSON 객체 하나만 돌려준다. 설명 · 코드 블록 없이.',
    '기존 스토리: {"story_id": "<목록의 id>", "reason": "<이유>"}',
    '새 스토리: {"new_story": "<이름>", "reason": "<이유>"}',
  ].join('\n');

  /// [dailyTitle] 은 이름이 빈 기본 스토리를 부를 이름(l10n).
  static String user(
    EntryDraft draft,
    List<StoryCandidate> candidates, {
    required String dailyTitle,
  }) {
    final place = draft.location?.placeName?.trim() ?? '';
    final lines = [
      '스토리 목록:',
      for (final c in candidates) ...[
        '- id: ${c.story.id} | 이름: ${_title(c.story, dailyTitle)}'
            '${c.story.isDefault ? ' (기본)' : ''}',
        for (final s in c.samples)
          if (_flat(s).isNotEmpty) '    · ${_clip(_flat(s), maxSampleLength)}',
      ],
      '',
      '새 일기:',
      '시각: ${_at.format(draft.occurredAt)}',
      if (place.isNotEmpty) '장소: $place',
      if (draft.tags.isNotEmpty)
        '태그: ${draft.tags.map((t) => '#$t').join(' ')}',
      '본문:',
      _clip(draft.body.trim(), maxBodyLength),
    ];
    return '${lines.join('\n')}\n';
  }

  /// 모델 답 → [StoryPick]. 쓸 수 없는 답이면 null.
  ///
  /// 첫 `{` 부터 마지막 `}` 까지를 JSON 으로 읽는다(코드 블록 · 앞뒤 말을 견딘다).
  /// `story_id` 가 [candidates] 에 없으면 null. `new_story` 이름이 기존 스토리 이름과 같으면
  /// (대소문자 · 앞뒤 공백 무시) 그 스토리로 바꾼다. 둘 다 있으면 `story_id` 를 먼저 본다.
  static StoryPick? parse(
    String text,
    List<StoryCandidate> candidates, {
    required String dailyTitle,
  }) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    final Object? json;
    try {
      json = jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final reason = switch (json['reason']) {
      final String r => _clip(_flat(r), maxReasonLength),
      _ => '',
    };

    final id = json['story_id'];
    if (id is String && id.trim().isNotEmpty) {
      final match = candidates
          .where((c) => c.story.id == id.trim())
          .firstOrNull;
      return match == null
          ? null
          : StoryPick.existing(storyId: match.story.id, reason: reason);
    }

    final name = json['new_story'];
    if (name is! String) return null;
    final title = _clip(_flat(name), maxTitleLength).trim();
    if (title.isEmpty) return null;
    final same = candidates.where(
      (c) =>
          _title(c.story, dailyTitle).trim().toLowerCase() ==
          title.toLowerCase(),
    );
    if (same.isNotEmpty) {
      return StoryPick.existing(storyId: same.first.story.id, reason: reason);
    }
    return StoryPick.create(title: title, reason: reason);
  }

  static String _title(Story story, String dailyTitle) =>
      story.title.trim().isEmpty && story.isDefault ? dailyTitle : story.title;

  static final _at = DateFormat('yyyy-MM-dd HH:mm');

  static String _flat(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 글자(rune) 기준으로 자른다 — 이모지 반쪽이 남지 않게.
  static String _clip(String text, int max) {
    final runes = text.runes;
    return runes.length <= max ? text : String.fromCharCodes(runes.take(max));
  }

  static String _languageName(String? locale) =>
      switch (locale?.split(RegExp('[_-]')).first) {
        null || 'ko' => '한국어',
        'en' => '영어(English)',
        'ja' => '일본어(日本語)',
        final code => "언어 코드 '$code' 의 언어",
      };
}
