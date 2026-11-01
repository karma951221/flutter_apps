import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/chat/entity/conversation.dart';
import '../../../../domain/chat/entity/wiki_note.dart';

part 'wiki_edit_state.freezed.dart';

/// 편집 화면을 여는 값. [id] 가 null 이면 새 메모. 편집 중엔 쓰던 글을 여기에 남긴다.
///
/// `toString` 은 제목 · 요약 · 본문 대신 길이만 담는다.
@freezed
class WikiEditSeed with _$WikiEditSeed {
  @override
  final int? id;
  @override
  final String title;
  @override
  final String summary;
  @override
  final String body;

  /// 출처 대화. 새 메모면 저장할 때 같이 남는다.
  @override
  final String? sourceConversationId;

  /// 일기 고르기 위쪽에 먼저 보일 근거 일기.
  @override
  final List<String> suggestedEntryIds;

  const WikiEditSeed({
    this.id,
    required this.title,
    required this.summary,
    required this.body,
    this.sourceConversationId,
    this.suggestedEntryIds = const [],
  });

  static WikiEditSeed fromNote(WikiNote note) => WikiEditSeed(
    id: note.id,
    title: note.title,
    summary: note.summary,
    body: note.body,
    sourceConversationId: note.sourceConversationId,
  );

  /// 편집 화면의 입력 상한(maxLength)을 넘지 않게 제목 · 요약 · 본문을 각 상한에서
  /// grapheme 단위로 자르고 끝 공백을 지운 값. 말풍선 · 정리 후보처럼 밖에서 온 글을 열 때 쓴다.
  static WikiEditSeed capped({
    int? id,
    required String title,
    required String summary,
    required String body,
    String? sourceConversationId,
    List<String> suggestedEntryIds = const [],
  }) => WikiEditSeed(
    id: id,
    title: _cap(title, wikiTitleMax),
    summary: _cap(summary, wikiSummaryMax),
    body: _cap(body, wikiBodyMax),
    sourceConversationId: sourceConversationId,
    suggestedEntryIds: suggestedEntryIds,
  );

  static String _cap(String s, int max) {
    final chars = s.characters;
    return chars.length <= max ? s : chars.take(max).string.trimRight();
  }

  /// [위키에 추가] — 제목 = conversationTitleFrom(질문), 요약 = 말풍선 글 첫 줄,
  /// 본문 = 말풍선 글 전체(각 상한에서 자름 — [capped]), 출처 = 지금 대화, 근거 일기 = 그 턴의 인용 id.
  static WikiEditSeed fromBubble({
    required String question,
    required String text,
    required String? conversationId,
    required List<String> citedEntryIds,
  }) {
    final body = text.trim();
    return capped(
      title: conversationTitleFrom(question),
      summary: body.split('\n').first.trim(),
      body: body,
      sourceConversationId: conversationId,
      suggestedEntryIds: [...citedEntryIds],
    );
  }

  @override
  String toString() =>
      'WikiEditSeed(id: $id, titleLength: ${title.length}, '
      'summaryLength: ${summary.length}, bodyLength: ${body.length}, '
      'sourceConversationId: $sourceConversationId, '
      'suggested: ${suggestedEntryIds.length})';
}

enum WikiEditError { emptyTitle, emptySummary, saveFailed }

@freezed
class WikiEditState with _$WikiEditState {
  /// 처음 연 값에 쓰던 글을 덧입힌 것.
  @override
  final WikiEditSeed seed;

  @override
  final bool saving;

  @override
  final WikiEditError? error;

  const WikiEditState({required this.seed, this.saving = false, this.error});

  /// 글은 [WikiEditSeed.toString] 이 뺀다.
  @override
  String toString() =>
      'WikiEditState(seed: $seed, saving: $saving, error: $error)';
}
