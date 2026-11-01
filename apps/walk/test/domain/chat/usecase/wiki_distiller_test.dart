import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/chat/chat_model.dart';
import 'package:walk/domain/chat/chat_usage_log.dart';
import 'package:walk/domain/chat/chat_vendor.dart';
import 'package:walk/domain/chat/entity/conversation.dart';
import 'package:walk/domain/chat/entity/wiki_note.dart';
import 'package:walk/domain/chat/repository/chat_history_repository.dart';
import 'package:walk/domain/chat/tool/tool_result.dart';
import 'package:walk/domain/chat/tool/wiki_tools.dart';
import 'package:walk/domain/chat/usecase/chat_model_choice.dart';
import 'package:walk/domain/chat/usecase/chat_session.dart';
import 'package:walk/domain/chat/usecase/wiki_distiller.dart';
import 'package:walk/domain/diary/entity/diary_entry.dart';
import 'package:walk/domain/diary/repository/diary_repository.dart';

import '../../../support/fake_chat_history.dart';
import '../../../support/fake_chat_key_verifier.dart';
import '../../../support/fake_chat_model_catalog.dart';
import '../../../support/fake_chat_model_registry.dart';
import '../../../support/fake_chat_settings.dart';
import '../../../support/fake_chat_usage_log.dart';
import '../../../support/fake_wiki_repository.dart';

class _Diary extends Mock implements DiaryRepository {}

class _WikiTools extends Mock implements WikiTools {}

class _History implements ChatHistoryRepository {
  final turnsById = <String, List<ChatTurnRecord>>{};

  @override
  Future<List<ChatTurnRecord>> turns(String conversationId) async =>
      turnsById[conversationId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'key-${++_n}';
}

class _FixedClock extends Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

/// 부를 때마다 준비된 라운드 하나를 흘리고 받은 요청을 모은다.
class _FakeModel implements ChatModel {
  _FakeModel(this.rounds);

  final List<List<Object>> rounds;
  final requests = <ModelRequest>[];
  List<Object>? repeat;

  @override
  bool get progressNotes => false;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  Stream<ModelEvent> stream(ModelRequest request) async* {
    final index = requests.length;
    requests.add(request);
    final round = index < rounds.length ? rounds[index] : repeat!;
    for (final item in round) {
      if (item is ModelEvent) {
        yield item;
      } else {
        throw item;
      }
    }
  }
}

/// 끝나지 않는 모델 — 취소가 구독을 끊는지 본다.
class _HangingModel implements ChatModel {
  var cancelled = false;
  var listened = false;

  @override
  bool get progressNotes => false;

  @override
  ChatVendor get vendor => ChatVendor.anthropic;

  @override
  Future<ModelListResult> listModels(String apiKey) async =>
      const ModelListResult.ok([]);

  @override
  Stream<ModelEvent> stream(ModelRequest request) {
    late StreamController<ModelEvent> c;
    c = StreamController<ModelEvent>(
      onListen: () => listened = true,
      onCancel: () => cancelled = true,
    );
    return c.stream;
  }
}

const _usage = TokenUsage(inputTokens: 10, outputTokens: 2);

ModelEvent _done(
  List<AssistantPart> parts,
  StopKind stop, {
  TokenUsage? usage = _usage,
}) => ModelEvent.completed(
  message: AssistantMessage(parts: parts),
  stop: stop,
  usage: usage,
);

List<Object> _answer(String text) => [
  ModelEvent.textDelta(text),
  _done([AssistantPart.text(text)], StopKind.endTurn),
];

List<Object> _json(List<Map<String, Object?>> candidates) =>
    _answer(jsonEncode({'candidates': candidates}));

List<Object> _readWiki(String id, List<int> ids) => [
  _done([
    AssistantPart.toolCall(id: id, name: 'read_wiki', input: {'ids': ids}),
  ], StopKind.toolUse),
];

ChatTurnRecord _turn(
  int seq,
  String q,
  String a, {
  List<String> cited = const [],
  bool stopped = false,
}) => ChatTurnRecord(
  conversationId: 'c1',
  seq: seq,
  question: q,
  answer: a,
  citedEntryIds: cited,
  stopped: stopped,
  vendor: ChatVendor.anthropic,
  model: 'claude-sonnet-9-5',
  askedAt: DateTime(2026, 10, 20),
);

DiaryEntry _entry(String id, DateTime at, {DateTime? deletedAt}) => DiaryEntry(
  id: id,
  storyId: 'daily',
  body: '본문',
  occurredAt: at,
  createdAt: at,
  updatedAt: at,
  deletedAt: deletedAt,
  media: const [],
  tags: const [],
);

const _rec = 'claude-sonnet-9-5';

final _models = [
  ModelInfo(id: _rec, displayName: _rec, createdAt: DateTime.utc(2026, 1, 5)),
];

String _userText(ModelRequest r) => (r.messages.first as UserMessage).text;

void main() {
  final clock = _FixedClock(DateTime(2026, 10, 21, 9));
  late FakeChatSettings settings;
  late ChatModelChoice choice;
  late FakeChatHistorySettings historySettings;
  late _History history;
  late FakeWikiRepository wiki;
  late _WikiTools wikiTools;
  late _Diary diary;
  late FakeChatUsageLog usage;
  late _SeqIds ids;

  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  setUp(() async {
    settings = FakeChatSettings('sk-ant-test-key');
    final catalog = FakeChatModelCatalog();
    await catalog.replace(ChatVendor.anthropic, _models, clock.value);
    final verifier = FakeChatKeyVerifier()
      ..stored = (ChatVendor.anthropic, ModelListResult.ok(_models));
    choice = ChatModelChoice(settings, catalog, verifier, clock);
    historySettings = FakeChatHistorySettings();
    history = _History()
      ..turnsById['c1'] = [
        _turn(1, '아침 알람 몇 시야?', '7시예요', cited: ['e1', 'e2']),
      ];
    wiki = FakeWikiRepository();
    wikiTools = _WikiTools();
    diary = _Diary();
    when(
      () => diary.entry(any()),
    ).thenAnswer((_) async => const Err(Failure.notFound()));
    when(
      () => diary.entry('e1'),
    ).thenAnswer((_) async => Ok(_entry('e1', DateTime(2026, 10, 3, 23))));
    when(
      () => diary.entry('e2'),
    ).thenAnswer((_) async => Ok(_entry('e2', DateTime(2026, 10, 4, 8))));
    usage = FakeChatUsageLog();
    ids = _SeqIds();
  });

  WikiDistiller distillerOf(ChatModel model) => WikiDistiller(
    FakeChatModelRegistry({ChatVendor.anthropic: model}),
    settings,
    choice,
    historySettings,
    history,
    wiki,
    wikiTools,
    diary,
    usage,
    ids,
    clock,
  );

  Future<WikiDistillResult> distill(ChatModel model, {String id = 'c1'}) =>
      distillerOf(model).distill(conversationId: id);

  List<WikiCandidate> candidatesOf(WikiDistillResult r) => switch (r) {
    WikiDistillCandidates(:final candidates) => candidates,
    _ => fail('expected candidates, got $r'),
  };

  group('요청', () {
    test('요청 user 글에 턴마다 질문 · 답과 근거 일기 id(날짜) 줄이 있다', () async {
      history.turnsById['c1'] = [
        _turn(1, '아침 알람 몇 시야?', '7시예요', cited: ['e1', 'e2']),
        _turn(2, '고마워', '천만에요'),
      ];
      final model = _FakeModel([_json([])]);

      await distill(model);

      expect(model.requests, hasLength(1));
      final r = model.requests.single;
      expect(r.messages, hasLength(1));
      final text = _userText(r);
      expect(text, contains('질문: 아침 알람 몇 시야?\n답: 7시예요\n'));
      expect(text, contains('[근거 일기: e1(2026-10-03), e2(2026-10-04)]'));
      expect(text, contains('질문: 고마워\n답: 천만에요'));
      expect('[근거 일기'.allMatches(text), hasLength(1));
    });

    test('휴지통 일기 id 는 근거 줄에서 빠진다', () async {
      when(() => diary.entry('e2')).thenAnswer(
        (_) async => Ok(
          _entry('e2', DateTime(2026, 10, 4), deletedAt: DateTime(2026, 10, 5)),
        ),
      );
      history.turnsById['c1'] = [
        _turn(1, 'q', 'a', cited: ['e1', 'e2', 'gone']),
        _turn(2, 'q2', 'a2', cited: ['e2']),
      ];
      final model = _FakeModel([_json([])]);

      await distill(model);

      final text = _userText(model.requests.single);
      expect(text, contains('[근거 일기: e1(2026-10-03)]'));
      expect(text, isNot(contains('e2')));
      expect(text, isNot(contains('gone')));
      expect('[근거 일기'.allMatches(text), hasLength(1));
    });

    test('멈춘 턴은 stoppedNote 가 붙는다', () async {
      history.turnsById['c1'] = [_turn(1, 'q', '중간까지', stopped: true)];
      final model = _FakeModel([_json([])]);

      await distill(model);

      expect(
        _userText(model.requests.single),
        contains('답: 중간까지\n${ChatSession.stoppedNote}'),
      );
    });

    test('25턴이면 마지막 20턴만', () async {
      history.turnsById['c1'] = [
        for (var i = 1; i <= 25; i++) _turn(i, '질문$i번', '답$i번'),
      ];
      final model = _FakeModel([_json([])]);

      await distill(model);

      final text = _userText(model.requests.single);
      for (var i = 1; i <= 5; i++) {
        expect(text, isNot(contains('질문$i번')));
      }
      for (var i = 6; i <= 25; i++) {
        expect(text, contains('질문$i번'));
      }
    });

    test('tools 에 일기 도구가 없다 — 메모가 있으면 read_wiki 하나, 없으면 빈 목록', () async {
      final empty = _FakeModel([_json([])]);
      await distill(empty);
      expect(empty.requests.single.tools, isEmpty);

      wiki.stored = [wikiNote(3)];
      final withNotes = _FakeModel([_json([])]);
      await distill(withNotes);
      expect(withNotes.requests.single.tools, [WikiTools.spec]);
    });

    test('system 에 지금 위키 색인과 출력 형식이 있다', () async {
      wiki.stored = [wikiNote(3, title: '출근 알람', summary: '평일 7시')];
      final model = _FakeModel([_json([])]);

      await distill(model);

      final system = model.requests.single.system;
      expect(
        system,
        contains('<wiki_index>\n[[3]] 출근 알람 — 평일 7시\n</wiki_index>'),
      );
      expect(system, contains('"candidates"'));
      expect(system, contains('"action"'));
      expect(system, contains('read_wiki'));
      expect(system, contains('2026-10-21'));
    });

    test('메모가 없으면 색인 절이 "(아직 메모 없음)"', () async {
      final model = _FakeModel([_json([])]);

      await distill(model);

      expect(model.requests.single.system, contains('(아직 메모 없음)'));
    });

    test('model 은 지금 고른 모델(ChatModelChoice), 키는 설정의 키', () async {
      final model = _FakeModel([_json([])]);

      await distill(model);

      expect(model.requests.single.model, _rec);
      expect(model.requests.single.apiKey, 'sk-ant-test-key');
    });

    test('target 을 넘기면 그 모델로', () async {
      final model = _FakeModel([_json([])]);

      await distillerOf(model).distill(
        conversationId: 'c1',
        target: (vendor: ChatVendor.anthropic, model: 'claude-x'),
      );

      expect(model.requests.single.model, 'claude-x');
    });

    test('키가 없으면 failed(noKey), 모델을 부르지 않는다', () async {
      settings.key = null;
      final model = _FakeModel([_json([])]);

      final r = await distill(model);

      expect(r, const WikiDistillResult.failed(ChatFailure.noKey));
      expect(model.requests, isEmpty);
    });

    test('고른 모델이 없으면 failed(noModels)', () async {
      final catalog = FakeChatModelCatalog();
      choice = ChatModelChoice(settings, catalog, FakeChatKeyVerifier(), clock);
      final model = _FakeModel([_json([])]);

      final r = await distill(model);

      expect(r, const WikiDistillResult.failed(ChatFailure.noModels));
      expect(model.requests, isEmpty);
    });

    test('턴이 없으면 모델을 부르지 않고 candidates([])', () async {
      final model = _FakeModel([_json([])]);

      final r = await distill(model, id: 'none');

      expect(r, const WikiDistillResult.candidates([]));
      expect(model.requests, isEmpty);
    });
  });

  group('파싱 · 거르기', () {
    test('JSON 후보를 읽는다 — 코드 펜스 · 앞뒤 말이 있어도', () async {
      final body = jsonEncode({
        'candidates': [
          {'action': 'new', 'title': '기상', 'summary': '7시 기상', 'body': '평일'},
        ],
      });
      final model = _FakeModel([_answer('여기요:\n```json\n$body\n```\n끝.')]);

      final r = await distill(model);

      expect(candidatesOf(r), [
        const WikiCandidate.create(title: '기상', summary: '7시 기상', body: '평일'),
      ]);
    });

    test('new 와 update', () async {
      wiki.stored = [wikiNote(3)];
      final model = _FakeModel([
        _json([
          {'action': 'new', 'title': 'a', 'summary': 's', 'body': 'b'},
          {'action': 'update', 'id': 3, 'title': 't', 'summary': 'u'},
        ]),
      ]);

      final r = await distill(model);

      expect(candidatesOf(r), [
        const WikiCandidate.create(title: 'a', summary: 's', body: 'b'),
        const WikiCandidate.update(id: 3, title: 't', summary: 'u', body: ''),
      ]);
    });

    test('없는 메모 id 의 update 는 create 로', () async {
      wiki.stored = [wikiNote(3)];
      final model = _FakeModel([
        _json([
          {'action': 'update', 'id': 99, 'title': 't', 'summary': 's'},
          {'action': 'update', 'title': 't2', 'summary': 's2'},
        ]),
      ]);

      final r = await distill(model);

      expect(candidatesOf(r), [
        const WikiCandidate.create(title: 't', summary: 's', body: ''),
        const WikiCandidate.create(title: 't2', summary: 's2', body: ''),
      ]);
    });

    test('제목 · 요약이 빈 항목은 버린다', () async {
      final model = _FakeModel([
        _json([
          {'action': 'new', 'title': '  ', 'summary': 's'},
          {'action': 'new', 'title': 't', 'summary': ''},
          {'action': 'new', 'summary': 's'},
          {'action': 'new', 'title': 3, 'summary': 's'},
          {'action': 'new', 'title': 'ok', 'summary': 'fine'},
        ]),
      ]);

      final r = await distill(model);

      expect(candidatesOf(r), [
        const WikiCandidate.create(title: 'ok', summary: 'fine', body: ''),
      ]);
    });

    test('9개면 앞 8개만', () async {
      final model = _FakeModel([
        _json([
          for (var i = 1; i <= 9; i++)
            {'action': 'new', 'title': 't$i', 'summary': 's'},
        ]),
      ]);

      final r = await distill(model);

      final list = candidatesOf(r);
      expect(list, hasLength(WikiDistiller.maxCandidates));
      expect((list.last as WikiCreateCandidate).title, 't8');
    });

    test('근거가 아닌 [[일기:x]] 와 없는 [[99]] 는 본문에서 빠진다', () async {
      wiki.stored = [wikiNote(3)];
      final model = _FakeModel([
        _json([
          {
            'action': 'new',
            'title': 't',
            'summary': 's',
            'body': '알람 [[3]] 기상 [[일기:e1]] 가짜 [[일기:x]] 없는 [[99]] 끝',
          },
        ]),
      ]);

      final r = await distill(model);

      expect(
        (candidatesOf(r).single as WikiCreateCandidate).body,
        '알람 [[3]] 기상 [[일기:e1]] 가짜 없는 끝',
      );
    });

    test('모양이 어긋난 링크([[일기: x]] · 전각 콜론 · [[ 3 ]])는 고쳐서 거른다', () async {
      wiki.stored = [wikiNote(3)];
      final model = _FakeModel([
        _json([
          {
            'action': 'new',
            'title': 't',
            'summary': 's',
            'body': 'a [[일기: e1]] b [[일기：x]] c [[ 3 ]] d [[일기 : y ]] e',
          },
        ]),
      ]);

      final r = await distill(model);

      expect(
        (candidatesOf(r).single as WikiCreateCandidate).body,
        'a [[일기:e1]] b c [[3]] d e',
      );
    });

    test('JSON 이 아니면 unparsable', () async {
      final r = await distill(_FakeModel([_answer('정리할 게 없네요')]));
      expect(r, const WikiDistillResult.unparsable());

      final broken = await distill(_FakeModel([_answer('{"candidates": [}')]));
      expect(broken, const WikiDistillResult.unparsable());

      final notList = await distill(
        _FakeModel([_answer('{"candidates": "없음"}')]),
      );
      expect(notList, const WikiDistillResult.unparsable());
    });

    test('candidates 가 비면 candidates([])', () async {
      final r = await distill(_FakeModel([_json([])]));

      expect(r, const WikiDistillResult.candidates([]));
    });
  });

  group('라운드', () {
    test('모델이 read_wiki 를 부르면 실행해 결과를 다음 요청에 싣는다', () async {
      wiki.stored = [wikiNote(3)];
      when(
        () => wikiTools.readWiki(any()),
      ).thenAnswer((_) async => const ToolResult(json: '{"notes":[3]}'));
      final model = _FakeModel([
        [
          _done([
            const AssistantPart.toolCall(
              id: 't1',
              name: 'read_wiki',
              input: {
                'ids': [3],
              },
            ),
            const AssistantPart.toolCall(
              id: 't2',
              name: 'search_diary',
              input: {},
            ),
          ], StopKind.toolUse),
        ],
        _json([]),
      ]);

      final r = await distill(model);

      expect(r, const WikiDistillResult.candidates([]));
      verify(
        () => wikiTools.readWiki({
          'ids': [3],
        }),
      ).called(1);
      final second = model.requests[1].messages;
      expect(second, hasLength(3));
      final results = (second[2] as ToolResultsMessage).results;
      expect(results[0].callId, 't1');
      expect(results[0].json, '{"notes":[3]}');
      expect(results[0].isError, isFalse);
      expect(results[1].callId, 't2');
      expect(results[1].isError, isTrue);
    });

    test('4라운드를 넘기면 failed(tooManySteps)', () async {
      when(
        () => wikiTools.readWiki(any()),
      ).thenAnswer((_) async => const ToolResult(json: '{}'));
      final model = _FakeModel([])..repeat = _readWiki('t', [1]);

      final r = await distill(model);

      expect(r, const WikiDistillResult.failed(ChatFailure.tooManySteps));
      expect(model.requests, hasLength(WikiDistiller.maxRounds));
    });

    test('refusal 은 failed(refused)', () async {
      final model = _FakeModel([
        [_done(const [], StopKind.refusal)],
      ]);

      expect(
        await distill(model),
        const WikiDistillResult.failed(ChatFailure.refused),
      );
    });

    test('invalidKey 예외는 failed(invalidKey)', () async {
      final model = _FakeModel([
        [const ChatModelException(ChatModelErrorKind.invalidKey)],
      ]);

      expect(
        await distill(model),
        const WikiDistillResult.failed(ChatFailure.invalidKey),
      );
    });

    test('완료 이벤트 없이 끝나면 failed(network)', () async {
      final model = _FakeModel([const <Object>[]]);

      expect(
        await distill(model),
        const WikiDistillResult.failed(ChatFailure.network),
      );
    });

    test(
      '사용량은 라운드마다 purpose wikiDistill · 같은 questionKey · temporary false',
      () async {
        wiki.stored = [wikiNote(3), wikiNote(4)];
        when(
          () => wikiTools.readWiki(any()),
        ).thenAnswer((_) async => const ToolResult(json: '{}'));
        final model = _FakeModel([
          _readWiki('t1', [3]),
          _json([]),
        ]);

        await distill(model);
        await pumpEventQueue();

        expect(usage.records, hasLength(2));
        for (final rec in usage.records) {
          expect(rec.purpose, ChatUsagePurpose.wikiDistill);
          expect(rec.questionKey, 'key-1');
          expect(rec.temporary, isFalse);
          expect(rec.vendor, ChatVendor.anthropic);
          expect(rec.model, _rec);
          expect(rec.wikiIndexNotes, 2);
          expect(rec.wikiIndexChars, greaterThan(0));
          expect(rec.inputTokens, 10);
        }
        expect(usage.records.map((r) => r.round), [1, 2]);
        expect(usage.records.map((r) => r.readWikiCalls), [1, 0]);
      },
    );

    test('사용량 기록이 실패해도 결과는 그대로', () async {
      usage.failWith = StateError('db');
      final r = await distill(_FakeModel([_json([])]));

      expect(r, const WikiDistillResult.candidates([]));
    });

    test('cancel 은 진행 중인 모델 구독을 끊고 cancelled 를 돌려준다', () async {
      final model = _HangingModel();
      final distiller = distillerOf(model);

      final future = distiller.distill(conversationId: 'c1');
      await pumpEventQueue();
      expect(model.listened, isTrue);
      distiller.cancel();

      expect(await future, const WikiDistillResult.cancelled());
      expect(model.cancelled, isTrue);
    });
  });

  test('toString 에 후보 글이 없다', () {
    const r = WikiDistillResult.candidates([
      WikiCandidate.create(title: '비밀제목', summary: '비밀요약', body: '비밀본문'),
    ]);
    expect(r.toString(), isNot(contains('비밀')));
  });
}
