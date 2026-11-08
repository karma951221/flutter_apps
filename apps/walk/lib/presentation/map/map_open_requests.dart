import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/diary/entity/story.dart';

/// 스토리 뷰어처럼 셸 바깥 라우트가 "이 스토리를 지도로 보여 줘" 하고 셸에 전하는 통로.
///
/// 뷰어는 루트 내비게이터에 올라 셸의 provider 밖이라 콜백을 받을 수 없다. 셸은 이 스트림을
/// 구독해 도구 › 지도로 바꾼다.
@lazySingleton
class MapOpenRequests {
  final _controller = StreamController<Story>.broadcast();

  Stream<Story> get requests => _controller.stream;

  void open(Story story) {
    if (_controller.isClosed) return;
    _controller.add(story);
  }

  @disposeMethod
  Future<void> dispose() => _controller.close();
}
