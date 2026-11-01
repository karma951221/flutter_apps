import 'package:freezed_annotation/freezed_annotation.dart';

part 'wiki_note.freezed.dart';

/// 위키 메모 하나(D5). id 는 모델에게 보이는 짧은 정수 — `[[12]]`.
///
/// `toString` 은 제목 · 요약 · 본문 대신 길이만 담는다.
@freezed
class WikiNote with _$WikiNote {
  @override
  final int id;
  @override
  final String title;

  /// 한 줄 요약. 색인에 실린다.
  @override
  final String summary;
  @override
  final String body;

  /// 처음 만든 대화. 그 대화를 지우면 null.
  @override
  final String? sourceConversationId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const WikiNote({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    this.sourceConversationId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String toString() =>
      'WikiNote(id: $id, titleLength: ${title.length}, '
      'bodyLength: ${body.length})';
}

/// 저장소에 넘기는 새 내용 / 고친 내용. 저장소가 trim · 한 줄 요약 · 상한 자르기를 한다.
@freezed
class WikiNoteDraft with _$WikiNoteDraft {
  @override
  final String title;
  @override
  final String summary;
  @override
  final String body;
  @override
  final String? sourceConversationId;

  const WikiNoteDraft({
    required this.title,
    required this.summary,
    required this.body,
    this.sourceConversationId,
  });

  @override
  String toString() =>
      'WikiNoteDraft(titleLength: ${title.length}, '
      'bodyLength: ${body.length})';
}

/// [위키로 정리] 후보(D6).
@freezed
sealed class WikiCandidate with _$WikiCandidate {
  const WikiCandidate._();

  const factory WikiCandidate.create({
    required String title,
    required String summary,
    required String body,
  }) = WikiCreateCandidate;

  const factory WikiCandidate.update({
    required int id,
    required String title,
    required String summary,
    required String body,
  }) = WikiUpdateCandidate;

  @override
  String toString() => switch (this) {
    WikiCreateCandidate(:final title, :final body) =>
      'WikiCandidate.create(titleLength: ${title.length}, '
          'bodyLength: ${body.length})',
    WikiUpdateCandidate(:final id, :final title, :final body) =>
      'WikiCandidate.update(id: $id, titleLength: ${title.length}, '
          'bodyLength: ${body.length})',
  };
}

@freezed
sealed class WikiLink with _$WikiLink {
  /// `[[12]]`
  const factory WikiLink.note(int id) = WikiNoteLink;

  /// `[[일기:<entryId>]]`
  const factory WikiLink.diary(String entryId) = WikiDiaryLink;
}

/// 본문을 글 조각과 링크 조각으로 나눈 것. 화면(링크 칩)이 쓴다.
@freezed
sealed class WikiSegment with _$WikiSegment {
  const factory WikiSegment.text(String text) = WikiTextSegment;

  /// [raw] 는 본문에 적힌 그대로(`[[12]]`).
  const factory WikiSegment.link(WikiLink link, String raw) = WikiLinkSegment;
}

const wikiTitleMax = 60;
const wikiSummaryMax = 120;
const wikiBodyMax = 4000;

const _diaryPrefix = '일기:';

/// 숫자는 앞자리 0 없이(`[[012]]` 는 글) — 저장소의 backlinks LIKE 와 같은 글자.
final _linkPattern = RegExp(r'\[\[(?:(0|[1-9]\d*)|일기:([^\s\[\]]+))\]\]');

/// `[[숫자]]` · `[[일기:id]]`(id 는 공백 · `[` · `]` 없는 글자). 그 밖의 `[[…]]` 는 글로 둔다.
List<WikiSegment> parseWikiBody(String body) {
  final segments = <WikiSegment>[];
  var textStart = 0;
  for (final m in _linkPattern.allMatches(body)) {
    final link = _linkOf(m);
    if (link == null) continue;
    if (m.start > textStart) {
      segments.add(WikiSegment.text(body.substring(textStart, m.start)));
    }
    segments.add(WikiSegment.link(link, m[0]!));
    textStart = m.end;
  }
  if (textStart < body.length) {
    segments.add(WikiSegment.text(body.substring(textStart)));
  }
  return segments;
}

/// 숫자가 int 를 넘으면 링크로 보지 않는다.
WikiLink? _linkOf(RegExpMatch m) {
  final digits = m[1];
  if (digits != null) {
    final id = int.tryParse(digits);
    return id == null ? null : WikiLink.note(id);
  }
  return WikiLink.diary(m[2]!);
}

/// 본문의 링크(나온 순서, 중복 제거).
List<WikiLink> wikiLinksIn(String body) => [
  ...{
    for (final s in parseWikiBody(body))
      if (s case WikiLinkSegment(:final link)) link,
  },
];

final _trailingSpaces = RegExp(r'[ \t]+$');
final _leadingSpaces = RegExp(r'^[ \t]+');

/// [keep] 이 false 인 링크 조각을 본문에서 지운다(앞뒤 공백 하나로 정리). Task 4 의 거르기.
///
/// 지운 자리 양쪽의 공백 · 탭은 하나로 줄이고, 줄 처음 · 끝이면 없앤다. 줄바꿈은 둔다.
String stripWikiLinks(String body, bool Function(WikiLink link) keep) {
  final out = StringBuffer();
  // 링크를 지운 뒤 아직 이어 붙일 글이 안 나왔다. 공백뿐인 조각은 이 상태를 이어 간다.
  var removed = false;
  for (final s in parseWikiBody(body)) {
    final String piece;
    switch (s) {
      case WikiLinkSegment(:final link, :final raw):
        if (!keep(link)) {
          removed = true;
          continue;
        }
        piece = raw;
      case WikiTextSegment(:final text):
        piece = text;
    }
    if (!removed) {
      out.write(piece);
      continue;
    }
    final after = piece.replaceFirst(_leadingSpaces, '');
    if (after.isEmpty) continue;
    removed = false;
    final before = out.toString().replaceFirst(_trailingSpaces, '');
    out
      ..clear()
      ..write(before);
    if (before.isNotEmpty &&
        !before.endsWith('\n') &&
        !after.startsWith('\n')) {
      out.write(' ');
    }
    out.write(after);
  }
  if (removed) return out.toString().replaceFirst(_trailingSpaces, '');
  return out.toString();
}

/// 링크 넣기 시트가 쓰는 문자열 — `[[12]]`.
String wikiNoteLinkText(int id) => '[[$id]]';

/// 링크 넣기 시트가 쓰는 문자열 — `[[일기:abc]]`.
String wikiDiaryLinkText(String entryId) => '[[$_diaryPrefix$entryId]]';
