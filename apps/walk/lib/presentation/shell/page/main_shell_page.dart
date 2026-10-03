import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../core/background/alarm_resync.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../../../domain/clock.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import '../../alarm/cubit/alarm_list_cubit.dart';
import '../../alarm/page/alarm_list_page.dart';
import '../../settings/cubit/settings_permissions_cubit.dart';
import '../../settings/page/settings_page.dart';
import '../../walk/page/walk_home_page.dart';

/// 하단 탭 순서. 첫 탭은 [walk] — 원래 한 화면짜리 앱이던 흐름을 지킨다.
enum ShellTab { alarm, walk, settings }

/// 하단 탭 셸. 탭마다 자기 `Scaffold` · `AppBar` 를 둔다.
///
/// 알람 예약 동기화(`AlarmUseCase.sync`)는 여기 한 곳에서 한다 — 시작과 복귀(resumed),
/// 그리고 앱이 떠 있을 때 시간대가 바뀌면 네이티브 수신기가 [backgroundChannel] 로 부르는 `resync`.
/// 알람 목록 · 설정 권한 cubit 을 소유해, 복귀하거나 위에 얹힌 화면(편집 · 울림)이
/// 걷힐 때 다시 읽는다.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with RouteAware {
  final _alarmUseCase = getIt<AlarmUseCase>();
  late final _alarms = AlarmListCubit(
    _alarmUseCase,
    getIt<AlarmPermissions>(),
    getIt<Clock>(),
  );
  late final _permissions = SettingsPermissionsCubit(
    getIt<AlarmPermissions>(),
    getIt<WalkUseCase>(),
  );
  late final AppLifecycleListener _lifecycle;
  ShellTab _tab = ShellTab.walk;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    backgroundChannel.setMethodCallHandler(_onBackgroundCall);
    _alarms.load();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    backgroundChannel.setMethodCallHandler(null);
    appRouteObserver.unsubscribe(this);
    _lifecycle.dispose();
    _alarms.close();
    _permissions.close();
    super.dispose();
  }

  /// 편집 · 울림 화면이 닫혔다 — 알람이 바뀌었거나 권한을 허용했을 수 있다.
  /// 알림 버튼으로 울림을 끈 경우에도 여기로 오므로 예약부터 다시 채운다.
  @override
  void didPopNext() => _refresh();

  /// 시작 · 복귀. 예약을 채운 뒤(지난 1회성이 꺼진 뒤) 목록을 읽는다.
  Future<void> _refresh() => _reload(_alarmUseCase.sync);

  Future<void> _reload(Future<void> Function() reschedule) async {
    _permissions.check();
    try {
      await reschedule();
    } on Object {
      // 부르는 쪽이 기다리지 않는다(시작 · 복귀 · 화면 복귀) — 예외를 올리면 잡을 곳이 없다.
      // 예약은 다음 복귀에 다시 채우고, 목록은 저장된 대로 보인다.
    }
    await _alarms.load();
  }

  /// 시간대가 바뀌었다 — 새 시간대의 벽시계로 예약을 다시 걸고 목록을 읽은 뒤 응답한다.
  Future<void> _onBackgroundCall(MethodCall call) async {
    if (call.method != 'resync') throw MissingPluginException();
    await _reload(_alarmUseCase.timeZoneChanged);
  }

  void _select(ShellTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _alarms),
        BlocProvider.value(value: _permissions),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            AlarmListPage(onOpenSettings: () => _select(ShellTab.settings)),
            WalkHomePage(active: _tab == ShellTab.walk),
            const SettingsPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (index) => _select(ShellTab.values[index]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.alarm_outlined),
              selectedIcon: const Icon(Icons.alarm),
              label: l10n.walkShellTabAlarm,
            ),
            NavigationDestination(
              icon: const Icon(Icons.directions_walk),
              label: l10n.walkShellTabWalk,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.walkShellTabSettings,
            ),
          ],
        ),
      ),
    );
  }
}
