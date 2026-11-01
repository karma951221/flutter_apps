import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import '../chat_history_settings.dart';
import '../chat_model.dart';
import '../repository/wiki_repository.dart';
import '../tool/wiki_tools.dart';
import 'wiki_index.dart';

part 'wiki_context_policy.freezed.dart';

/// 이번 질문에 붙일 위키. systemSection 이 null 이면 위키 절 없음.
@freezed
class WikiContext with _$WikiContext {
  /// 시스템 프롬프트에 넣을 위키 절. null 이면 넣지 않는다.
  @override
  final String? systemSection;

  /// 이번 요청에 더할 도구 정의.
  @override
  final List<ToolSpec> tools;

  /// 색인에 실린 메모 수(사용량 행).
  @override
  final int indexNotes;

  /// 색인 글자 수(사용량 행).
  @override
  final int indexChars;

  const WikiContext({
    required this.systemSection,
    required this.tools,
    required this.indexNotes,
    required this.indexChars,
  });

  static const none = WikiContext(
    systemSection: null,
    tools: [],
    indexNotes: 0,
    indexChars: 0,
  );

  @override
  String toString() =>
      'WikiContext(section: ${systemSection != null}, tools: ${tools.length}, '
      'indexNotes: $indexNotes, indexChars: $indexChars)';
}

abstract interface class WikiContextPolicy {
  /// 이번 질문에 붙일 시스템 프롬프트 조각과 도구 정의(D8). question 은 후속 "미리 골라 붙이기" 자리.
  Future<WikiContext> build({required String question});
}

/// 기본: 색인만 시스템 프롬프트에, 본문은 read_wiki 로(D7). 메모가 0 개면 WikiContext.none.
@LazySingleton(as: WikiContextPolicy)
class IndexAndReadPolicy implements WikiContextPolicy {
  IndexAndReadPolicy(this._wiki, this._settings);

  final WikiRepository _wiki;
  final ChatHistorySettings _settings;

  static const _guide =
      '사용자가 정리해 둔 위키가 있다. 아래는 색인(id · 제목 · 한 줄 요약)이다.\n'
      '질문에 도움이 될 때만 read_wiki 로 본문을 열고, 본문의 [[id]] 링크를 따라 더 열 수 있다.\n'
      '본문의 [[일기:<id>]] 는 일기 기록이다 — read_wiki 가 날짜를 주니 원본이 필요하면 그 날짜로 search_diary 를 부른다.\n'
      '위키와 기록 도구로 찾은 내용이 다르면 기록을 우선하고 다르다고 말한다.';

  @override
  Future<WikiContext> build({required String question}) async {
    final notes = await _wiki.all();
    if (notes.isEmpty) return WikiContext.none;
    final index = buildWikiIndex(notes, _settings.wikiIndexSize);
    return WikiContext(
      systemSection: '$_guide\n<wiki_index>\n${index.lines}\n</wiki_index>',
      tools: const [WikiTools.spec],
      indexNotes: index.includedIds.length,
      indexChars: index.chars,
    );
  }
}

/// 임시 대화 · 위키 없음.
class NoWikiPolicy implements WikiContextPolicy {
  const NoWikiPolicy();

  @override
  Future<WikiContext> build({required String question}) async =>
      WikiContext.none;
}
