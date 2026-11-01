import 'package:walk/domain/chat/chat_trace.dart';

/// 찍힌 표시를 차례로 모으는 가짜. begin · end 도 `begin` · `end` 표시로 남긴다.
class RecordingChatTrace implements ChatTrace {
  RecordingChatTrace({this.enabled = true});

  @override
  final bool enabled;

  /// (표시 이름, data) 차례.
  final marks = <(String, Map<String, Object?>)>[];

  /// 표시 이름만.
  List<String> get labels => [for (final m in marks) m.$1];

  /// 이 이름의 data 들.
  List<Map<String, Object?>> dataOf(String label) => [
    for (final m in marks)
      if (m.$1 == label) m.$2,
  ];

  @override
  void begin() => marks.add(('begin', const {}));

  @override
  void mark(String label, [Map<String, Object?> data = const {}]) =>
      marks.add((label, Map.unmodifiable(data)));

  @override
  void end() => marks.add(('end', const {}));
}
