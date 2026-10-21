import 'dart:async';

import 'package:alarm/alarm.dart' as pkg;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// 앱이 살아 있을 때 울리기 시작한 알람마다 울림 화면을 한 번씩 띄운다.
///
/// 시작할 때 한 번 [start] 한다. 알림 버튼처럼 앱 밖에서 끄거나 미뤄 울림이 끝나면
/// 그 화면을 걷는다. 화면 쪽에서 끄면(화면이 먼저 닫히면) 여기서는 아무것도 하지 않는다.
///
/// 안전망: 앱으로 돌아올 때(resume) 열린 울림 화면마다 [isRinging] 으로 플랫폼에 다시 묻고, 이미
/// 안 울리면 그 화면을 걷는다 — 앱이 백그라운드에 있는 동안 끝났다는 값을 놓쳤거나 늦은 "울림" 값이
/// 화면을 다시 띄웠어도 꺼진 알람의 화면이 남지 않게. [isRinging] 이 없으면 묻지 않는다.
class AlarmRingListener {
  AlarmRingListener({
    required GlobalKey<NavigatorState> navigatorKey,
    required Route<void> Function(int packageId) routeFor,
    Stream<Set<int>>? ringing,
    Future<bool> Function(int packageId)? isRinging,
  }) : _navigatorKey = navigatorKey,
       _routeFor = routeFor,
       _ringing = ringing ?? packageRinging(),
       _isRinging = isRinging;

  final GlobalKey<NavigatorState> _navigatorKey;
  final Route<void> Function(int packageId) _routeFor;
  final Stream<Set<int>> _ringing;
  final Future<bool> Function(int packageId)? _isRinging;
  AppLifecycleListener? _lifecycle;

  final _routes = <int, Route<void>>{};
  StreamSubscription<Set<int>>? _subscription;
  Set<int> _latest = const {};
  bool _waitingForNavigator = false;

  /// `alarm` 패키지의 울리는 알람들(패키지 id). 구독하면 현재 값부터 받는다 —
  /// 전체 화면 알림으로 앱이 막 켜진 경우에도 울림 화면이 뜬다.
  static Stream<Set<int>> packageRinging() =>
      pkg.Alarm.ringing.map((set) => {for (final settings in set.alarms) settings.id});

  /// 플랫폼이 그 알람을 지금 울리고 있는가(`alarm` 패키지).
  static Future<bool> packageIsRinging(int packageId) => pkg.Alarm.isRinging(packageId);

  void start() {
    _subscription ??= _ringing.listen(_onRinging);
    if (_isRinging != null) _lifecycle ??= AppLifecycleListener(onResume: _verifyOnResume);
  }

  Future<void> dispose() async {
    _lifecycle?.dispose();
    _lifecycle = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  /// 열린 울림 화면 가운데 플랫폼이 이미 안 울린다는 것을 걷는다. id 는 [_routes] 에 둔다 —
  /// 끝났다는 값이 올 때까지 같은 "울림" 값으로 다시 띄우지 않게(화면에서 끈 경우와 같다).
  Future<void> _verifyOnResume() async {
    final isRinging = _isRinging;
    if (isRinging == null) return;
    for (final MapEntry(key: id, value: route) in [..._routes.entries]) {
      if (!route.isActive) continue;
      final bool stillRinging;
      try {
        stillRinging = await isRinging(id);
      } on Object {
        continue;
      }
      if (stillRinging || _subscription == null || _routes[id] != route) continue;
      _close(route);
    }
  }

  void _close(Route<void> route) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }
  }

  void _onRinging(Set<int> ids) {
    _latest = ids;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // 첫 프레임 전(내비게이터가 아직 없음)에 받은 값은 프레임 뒤에 반영한다.
      if (!_waitingForNavigator) {
        _waitingForNavigator = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _waitingForNavigator = false;
          _onRinging(_latest);
        });
      }
      return;
    }
    for (final id in [..._routes.keys]) {
      if (ids.contains(id)) continue;
      _close(_routes.remove(id)!);
    }
    for (final id in ids) {
      if (_routes.containsKey(id)) continue;
      final route = _routeFor(id);
      _routes[id] = route;
      // 화면에서 끄기 · 미루기로 닫혀도 id 는 울림이 끝났다는 값이 올 때까지 둔다 —
      // 늦게 도착한 "아직 울림" 값으로 같은 화면을 다시 띄우지 않게.
      unawaited(navigator.push(route));
    }
  }
}
