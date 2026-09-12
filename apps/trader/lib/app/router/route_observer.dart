import 'package:flutter/material.dart';

/// 앱 내비게이터에 붙는 단 하나의 [RouteObserver].
///
/// 자기 위에 얹힌 화면이 걷히는 순간(`didPopNext`)을 알아야 하는 화면이
/// 구독한다. `push` 가 돌려주는 future 를 기다리는 방법도 있지만, 그 future 는
/// 얹은 화면이 `pushReplacement` 로 갈아치워지면 영영 끝나지 않는다 —
/// go_router 가 갈아치운 imperative match 의 completer 를 완료하지 않고 버리기
/// 때문이다. 그래서 "돌아왔다"는 신호는 push 한 쪽이 아니라 내비게이터에서
/// 받는다.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
