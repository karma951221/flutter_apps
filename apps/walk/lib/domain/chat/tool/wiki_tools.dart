import 'dart:convert';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../../diary/repository/diary_repository.dart';
import '../chat_model.dart';
import '../entity/wiki_note.dart';
import '../repository/wiki_repository.dart';
import 'tool_result.dart';
import 'tool_summary.dart';

/// 모델이 위키 메모 본문을 여는 도구(D7). 결과는 인용 칩을 만들지 않는다(W12).
@lazySingleton
class WikiTools {
  WikiTools(this._wiki, this._diary);

  final WikiRepository _wiki;
  final DiaryRepository _diary;

  static const readWikiName = 'read_wiki';
  static const maxIdsPerCall = 5;

  static const ToolSpec spec = ToolSpec(
    name: readWikiName,
    description:
        '위키 메모의 본문을 연다(한 번에 최대 5개). 본문의 [[id]] 는 다른 메모, '
        '[[일기:<id>]] 는 일기 기록이고, 결과에 링크된 메모 제목과 일기 날짜가 함께 온다.',
    parameters: {
      'type': 'object',
      'properties': {
        'ids': {
          'type': 'array',
          'items': {'type': 'integer'},
          'description': '열 메모 id(색인의 [[id]] 숫자). 최대 5개',
        },
      },
      'required': ['ids'],
    },
  );

  /// input['ids'] — 정수 · 숫자 문자열 · "3,7" 문자열을 받아 앞 5개만. 결과는 entryIds 없음(인용 칩 아님).
  Future<ToolResult> readWiki(Map<String, Object?> input) async {
    final ids = _ids(input['ids']);
    if (ids == null || ids.isEmpty) return _error('invalid_ids');
    try {
      final read = ids.take(maxIdsPerCall).toList();
      final skipped = ids.skip(maxIdsPerCall).toList();
      final found = {for (final n in await _wiki.byIds(read)) n.id: n};

      final links = {
        for (final note in found.values) note.id: wikiLinksIn(note.body),
      };
      final linkedIds = {
        for (final list in links.values)
          for (final link in list)
            if (link case WikiNoteLink(:final id)) id,
      }.toList();
      final linked = linkedIds.isEmpty
          ? const <int, WikiNote>{}
          : {for (final n in await _wiki.byIds(linkedIds)) n.id: n};
      final dates = <String, String?>{};
      for (final list in links.values) {
        for (final link in list) {
          if (link case WikiDiaryLink(:final entryId)) {
            if (!dates.containsKey(entryId)) {
              dates[entryId] = await _diaryDate(entryId);
            }
          }
        }
      }

      return ToolResult(
        json: jsonEncode({
          'notes': [
            for (final id in read)
              if (found[id] case final note?)
                _noteJson(note, links[id]!, linked, dates)
              else
                {'id': id, 'error': 'not_found'},
          ],
          if (skipped.isNotEmpty) 'skipped': skipped,
        }),
        summary: ToolSummary(kind: ChatToolKind.wiki, count: found.length),
      );
    } catch (_) {
      return _error('tool_failed');
    }
  }

  Map<String, Object?> _noteJson(
    WikiNote note,
    List<WikiLink> links,
    Map<int, WikiNote> linked,
    Map<String, String?> dates,
  ) => {
    'id': note.id,
    'title': note.title,
    'summary': note.summary,
    'body': note.body,
    'links': [
      for (final link in links)
        if (link case WikiNoteLink(:final id))
          if (linked[id] case final target?)
            {'id': id, 'title': target.title}
          else
            {'id': id, 'missing': true},
    ],
    'diary': [
      for (final link in links)
        if (link case WikiDiaryLink(:final entryId))
          if (dates[entryId] case final date?)
            {'entry_id': entryId, 'date': date}
          else
            {'entry_id': entryId, 'missing': true},
    ],
    'updated': _day(note.updatedAt),
  };

  /// 살아 있는 일기의 날짜. 없거나 휴지통이면 null.
  Future<String?> _diaryDate(String entryId) async =>
      switch (await _diary.entry(entryId)) {
        Ok(:final value) when !value.isTrashed => _day(value.occurredAt),
        _ => null,
      };

  /// 정수 · 정수 문자열 · "3,7" 을 받는다. 모양이 틀리면 null. 순서 유지 · 중복 제거.
  static List<int>? _ids(Object? raw) {
    final parts = <Object?>[if (raw is List) ...raw else raw];
    final ids = <int>{};
    for (final part in parts) {
      switch (part) {
        case int value:
          ids.add(value);
        case double value when value == value.truncateToDouble():
          ids.add(value.toInt());
        case String value:
          for (final piece in value.split(',')) {
            final id = int.tryParse(piece.trim());
            if (id == null) return null;
            ids.add(id);
          }
        default:
          return null;
      }
    }
    return ids.toList();
  }

  static ToolResult _error(String code) => ToolResult(
    json: jsonEncode({'error': code}),
    isError: true,
    summary: const ToolSummary(
      kind: ChatToolKind.wiki,
      count: 0,
      isError: true,
    ),
  );

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
}
