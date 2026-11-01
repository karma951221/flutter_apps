import 'dart:developer' as developer;

import '../../domain/chat/chat_trace.dart';

/// 디버그 · 프로필 빌드의 [ChatTrace]. 질문이 끝나면 요약 한 줄을
/// `developer.log(name: 'chat.trace')` 로 내고, 표시마다 `Timeline.instantSync`
/// 를 남겨 DevTools 에서 프레임과 겹쳐 본다.
///
/// 시간은 [begin] 기준 단조 ms. data 는 허용한 키만 남긴다 — 본문 · 키 · 도구
/// 입력값이 섞여 들어와도 버린다.
class DevChatTrace implements ChatTrace {
  DevChatTrace({
    void Function(String line)? emit,
    Stopwatch Function()? stopwatch,
  }) : _emit = emit ?? _log,
       _newStopwatch = stopwatch ?? Stopwatch.new;

  final void Function(String line) _emit;
  final Stopwatch Function() _newStopwatch;

  /// 남기는 data 키. 이름 · 개수 · 토큰 수 · stop 종류뿐이다.
  static const allowedKeys = {
    'vendor',
    'model',
    'fast',
    'kind',
    'tool',
    'n',
    'chars',
    'stop',
    'in',
    'out',
    'cacheRead',
    'cacheWrite',
    'reasoning',
  };

  static void _log(String line) => developer.log(line, name: 'chat.trace');

  /// 질문 순번. [begin] 마다 올린다.
  int _question = 0;
  _Question? _current;

  @override
  bool get enabled => true;

  @override
  void begin() {
    _question++;
    _current = _Question(
      _question,
      _newStopwatch()
        ..reset()
        ..start(),
    );
  }

  @override
  void mark(String label, [Map<String, Object?> data = const {}]) {
    final kept = {
      for (final e in data.entries)
        if (allowedKeys.contains(e.key)) e.key: e.value,
    };
    developer.Timeline.instantSync('chat.$label', arguments: kept);
    _current?.add(label, kept);
  }

  @override
  void end() {
    final question = _current;
    _current = null;
    if (question != null) _emit(question.summary());
  }
}

/// 질문 하나의 표시 모음.
final class _Question {
  _Question(this.number, this._watch);

  final int number;
  final Stopwatch _watch;

  Object? _vendor;
  Object? _model;
  Object? _fast;
  int? _key;

  /// 라운드와 도구 실행을 일어난 차례로.
  final _segments = <Object>[];
  _Round? _round;
  _Span? _tool;

  /// 끝 쪽 표시(firstVisible · firstGlyph · userStop · abort · done) → ms.
  final _tail = <String, int>{};

  static const _tailOrder = [
    ChatTraceMark.firstVisible,
    ChatTraceMark.firstGlyph,
    ChatTraceMark.userStop,
    ChatTraceMark.abort,
    ChatTraceMark.done,
  ];

  int get _now => _watch.elapsedMilliseconds;

  /// 라운드 표시 없이 model 표시가 오면 r1 로 묶는다.
  _Round _roundOrNew() {
    final round = _round;
    if (round != null) return round;
    final created = _Round(1);
    _round = created;
    _segments.add(created);
    return created;
  }

  void add(String label, Map<String, Object?> data) {
    final now = _now;
    switch (label) {
      case ChatTraceMark.key:
        _key = now;
      case ChatTraceMark.round:
        final n = data['n'];
        final round = _Round(n is int ? n : _roundCount + 1);
        _round = round;
        _segments.add(round);
      case ChatTraceMark.req:
        _vendor ??= data['vendor'];
        _model ??= data['model'];
        _fast ??= data['fast'];
        _roundOrNew();
      case ChatTraceMark.head:
        _roundOrNew().head = now;
      case ChatTraceMark.first:
        _roundOrNew().first = now;
      case ChatTraceMark.blockStart:
        final kind = data['kind'];
        final name = switch (kind) {
          'thinking' => 'think',
          'tool_use' => 'tool:${data['tool'] ?? '?'}',
          _ => null,
        };
        _roundOrNew().blocks.add(_Span(name, now));
      case ChatTraceMark.blockStop:
        final open = _roundOrNew().blocks.lastWhereOrNull((b) => b.end == null);
        open?.end = now;
      case ChatTraceMark.textDelta:
        final chars = data['chars'];
        _roundOrNew().deltas.add((now, chars is int ? chars : 0));
      case ChatTraceMark.progress:
        _roundOrNew().firstProgress ??= now;
      case ChatTraceMark.msgStop:
        final round = _roundOrNew()
          ..stop = now
          ..stopKind = data['stop'];
        for (final key in const [
          'in',
          'out',
          'cacheRead',
          'cacheWrite',
          'reasoning',
        ]) {
          final value = data[key];
          if (value is int) round.tokens[key] = value;
        }
      case ChatTraceMark.toolStart:
        final tool = _Span('tool:${data['tool'] ?? '?'}', now);
        _tool = tool;
        _segments.add(tool);
      case ChatTraceMark.toolEnd:
        final tool = _tool;
        if (tool != null) {
          tool
            ..end = now
            ..count = data['n'] is int ? data['n']! as int : null;
        }
        _tool = null;
      default:
        if (_tailOrder.contains(label)) _tail.putIfAbsent(label, () => now);
    }
  }

  int get _roundCount => _segments.whereType<_Round>().length;

  String summary() {
    final fast = switch (_fast) {
      true => '1',
      false => '0',
      final Object other => '$other',
      null => null,
    };
    final parts = <String>[
      'chat.trace q=$number',
      if (_vendor != null) 'vendor=$_vendor',
      if (_model != null) 'model=$_model',
      if (fast != null) 'fast=$fast',
      'rounds=$_roundCount',
      if (_key != null) 'key=$_key',
      for (final segment in _segments)
        switch (segment) {
          final _Round round => round.summary(),
          final _Span tool => tool.summary(),
          _ => '',
        },
      for (final label in _tailOrder)
        if (_tail[label] case final ms?) '$label=$ms',
    ];
    return parts.join(' ');
  }
}

/// 시작-끝 구간 하나(블록 · 도구 실행). [name] 이 null 이면 요약에서 뺀다(text 블록).
final class _Span {
  _Span(this.name, this.start);

  final String? name;
  final int start;
  int? end;

  /// 도구 결과 개수.
  int? count;

  String summary() {
    final count = this.count;
    return '$name=$start-${end ?? ''}${count == null ? '' : '(n=$count)'}';
  }
}

/// 라운드 하나.
final class _Round {
  _Round(this.number);

  final int number;
  int? head;
  int? first;

  /// 첫 진행 노트(`progress`) 시각.
  int? firstProgress;
  int? stop;
  Object? stopKind;
  final blocks = <_Span>[];

  /// (ms, 글자 수).
  final deltas = <(int, int)>[];

  /// in · out · cacheRead · cacheWrite · reasoning.
  final tokens = <String, int>{};

  String summary() {
    final parts = <String>[
      if (head != null) 'head=$head',
      if (first != null) 'first=$first',
      for (final block in blocks)
        if (block.name != null) block.summary(),
      if (firstProgress != null) 'firstProgress=$firstProgress',
      ..._deltaParts(),
      if (stop != null) 'stop=$stop${_unusualStop()}',
      for (final key in const ['in', 'out'])
        if (tokens[key] case final value?) '$key=$value',
      for (final key in const ['cacheRead', 'cacheWrite', 'reasoning'])
        if (tokens[key] case final value? when value != 0) '$key=$value',
    ];
    return 'r$number{${parts.join(' ')}}';
  }

  /// 흔한 끝(toolUse · endTurn)이 아니면 `(종류)` 를 붙인다.
  String _unusualStop() => switch (stopKind) {
    null || 'toolUse' || 'endTurn' => '',
    final kind => '($kind)',
  };

  List<String> _deltaParts() {
    if (deltas.isEmpty) return const [];
    final firstAt = deltas.first.$1;
    final span = deltas.last.$1 - firstAt;
    final largest = deltas.map((d) => d.$2).reduce((a, b) => a > b ? a : b);
    final gaps = [
      for (var i = 1; i < deltas.length; i++) deltas[i].$1 - deltas[i - 1].$1,
    ]..sort();
    return [
      'firstText=$firstAt',
      'deltas=${deltas.length}/${span}ms',
      'max=${largest}ch',
      if (gaps.isNotEmpty) 'gap~${_median(gaps)}ms',
    ];
  }

  static int _median(List<int> sorted) {
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }
}

extension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
