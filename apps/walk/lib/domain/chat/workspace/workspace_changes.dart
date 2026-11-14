import 'dart:async';

import 'package:injectable/injectable.dart';

/// 작업 폴더가 바뀌었다는 신호 하나(내용 없음). 쓰기 도구가 실행에 성공하면 알리고, 열린
/// 작업 폴더 화면이 듣고 목록을 다시 읽는다. 듣는 쪽이 없으면 버린다.
@lazySingleton
class WorkspaceChanges {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() => _controller.add(null);
}
