import 'package:freezed_annotation/freezed_annotation.dart';

import '../chat_history_settings.dart';
import '../entity/wiki_note.dart';

part 'wiki_index.freezed.dart';

/// 시스템 프롬프트 `<wiki_index>` 안에 실을 색인(W1). 정책과 위키 화면이 같이 쓴다.
@freezed
class WikiIndex with _$WikiIndex {
  /// `<wiki_index>` 안쪽. 줄바꿈으로 잇고, 생략이 있으면 끝에 생략 줄.
  @override
  final String lines;

  /// 색인에 실린 메모 id(최근 순).
  @override
  final List<int> includedIds;

  /// 상한에 걸려 빠진 메모 수.
  @override
  final int omitted;

  const WikiIndex({
    required this.lines,
    required this.includedIds,
    required this.omitted,
  });

  static const empty = WikiIndex(lines: '', includedIds: [], omitted: 0);

  /// [lines] 의 글자 수.
  int get chars => lines.length;

  @override
  String toString() =>
      'WikiIndex(notes: ${includedIds.length}, omitted: $omitted, '
      'chars: $chars)';
}

/// [notes] 는 updatedAt 최근 순. 제목 · 요약의 공백 · 줄바꿈은 공백 하나로 접어 메모 하나 = 한 줄.
/// 한 줄 = '[[id]] 제목 — 요약'. 앞에서부터 개수 < maxNotes 이고
/// (지금 글자 + 줄 + 줄바꿈) <= maxChars 인 동안 넣고, 처음 안 맞는 메모에서 멈춘다(뒤의 짧은 메모로 건너뛰지 않음).
/// omitted > 0 이면 끝 줄 '(오래된 메모 n개 생략)'(이 줄은 상한 계산 밖).
/// [notes] 가 앞의 [wikiIndexWindow] 개만이면 [total] 에 전체 수를 넘겨 omitted 를 맞춘다.
WikiIndex buildWikiIndex(
  List<WikiNote> notes,
  WikiIndexSize size, {
  int? total,
}) {
  if (notes.isEmpty) return WikiIndex.empty;
  final maxNotes = size.maxNotes;
  final lines = <String>[];
  final ids = <int>[];
  var used = 0;
  for (final note in notes) {
    if (maxNotes != null && ids.length >= maxNotes) break;
    final line =
        '${wikiNoteLinkText(note.id)} ${_oneLine(note.title)} — '
        '${_oneLine(note.summary)}';
    final cost = line.length + 1;
    if (used + cost > size.maxChars) break;
    lines.add(line);
    ids.add(note.id);
    used += cost;
  }
  final omitted = (total ?? notes.length) - ids.length;
  if (omitted > 0) lines.add('(오래된 메모 $omitted개 생략)');
  return WikiIndex(lines: lines.join('\n'), includedIds: ids, omitted: omitted);
}

/// 색인에 실릴 수 있는 메모 수의 상한 — 최근 순으로 이만큼만 읽으면 [buildWikiIndex] 의
/// includedIds 가 전체를 읽은 것과 같다. 개수 상한이 없으면 가장 짧은 줄
/// '[[1]] a — b'(11자 + 줄바꿈)로 글자 상한을 나눈다.
int wikiIndexWindow(WikiIndexSize size) =>
    size.maxNotes ?? size.maxChars ~/ _shortestLineCost;

const _shortestLineCost = 12;

final _spaces = RegExp(r'\s+');

String _oneLine(String text) => text.replaceAll(_spaces, ' ').trim();
