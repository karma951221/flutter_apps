import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../core/background/background_task.dart';
import '../../../domain/alarm/holiday/holiday_calendar.dart';
import '../../../domain/alarm/holiday/holiday_calendar_access.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../../../domain/alarm/widget/next_alarm_widget.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../../domain/diary/repository/diary_repository.dart';
import '../../../domain/diary/usecase/diary_use_case.dart';
import '../../../domain/lock/device_auth.dart';
import '../../../domain/lock/lock_repository.dart';
import '../../../domain/settings/repository/settings_repository.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import '../../alarm/cubit/alarm_list_cubit.dart';
import '../../alarm/page/alarm_list_page.dart';
import '../../commute/page/commute_tab.dart';
import '../../diary/page/diary_tab.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/media_pick_guard.dart';
import '../../settings/cubit/diary_settings_cubit.dart';
import '../../settings/cubit/holiday_settings_cubit.dart';
import '../../settings/cubit/settings_permissions_cubit.dart';
import '../../settings/page/settings_page.dart';
import '../../walk/page/walk_home_page.dart';

/// 하단 탭 순서. 첫 탭은 [walk] — 원래 한 화면짜리 앱이던 흐름을 지킨다.
enum ShellTab { alarm, walk, diary, commute, settings }

/// 하단 탭 셸. 탭마다 자기 `Scaffold` · `AppBar` 를 둔다.
///
/// 알람 예약 동기화(`AlarmUseCase.sync`)는 여기 한 곳에서 한다 — 시작과 복귀(resumed),
/// 그리고 앱이 떠 있을 때 네이티브 `BackgroundDispatcher`(시간대 변경 · 하루 한 번 작업 ·
/// 미리 알림 액션)가 [backgroundChannel] 로 부르는 `resync` · `reminderAction`. 그 앞에 공휴일 캐시(`HolidayRefresher`)를 갱신한다.
/// 알람 목록 · 설정 권한 · 설정 알람 섹션(공휴일) cubit 을 소유해, 복귀하거나 위에 얹힌
/// 화면(편집 · 울림)이 걷힐 때 다시 읽는다.
///
/// 일기 잠금([DiaryLockCubit])도 여기 하나를 두고 `BlocProvider` 로 내린다 — 일기 탭의 게이트와
/// 설정 탭(잠금 설정 뒤 `configChanged`)이 같은 것을 본다. 앱 생명주기(pause · resume)를 넘겨
/// 백그라운드 경과로 다시 잠근다. 알람 울림 화면은 셸 바깥 라우트라 일기 잠금과 무관하다.
/// 시작할 때 일기 고아 미디어 청소([DiaryUseCase.cleanOrphans])를 한 번, 기다리지 않고 부른다.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> with RouteAware {
  final _alarmUseCase = getIt<AlarmUseCase>();
  final _holidays = getIt<HolidayRefresher>();
  final _homeWidget = getIt<NextAlarmWidget>();
  late final _alarms = AlarmListCubit(
    _alarmUseCase,
    getIt<AlarmPermissions>(),
    getIt<Clock>(),
    getIt<HolidayCalendar>(),
  );
  late final _holidaySettings = HolidaySettingsCubit(
    getIt<SettingsRepository>(),
    getIt<HolidayCalendar>(),
    getIt<HolidayCalendarAccess>(),
    _alarmUseCase,
  );
  late final _permissions = SettingsPermissionsCubit(
    getIt<AlarmPermissions>(),
    getIt<WalkUseCase>(),
  );
  late final _diaryLock = DiaryLockCubit(
    getIt<LockRepository>(),
    getIt<DeviceAuth>(),
    getIt<Clock>(),
    getIt<MediaPickGuard>(),
  );
  late final _diarySettings = DiarySettingsCubit(
    getIt<LockRepository>(),
    getIt<DiaryPreferences>(),
    getIt<DiaryRepository>(),
  );
  late final AppLifecycleListener _lifecycle;
  ShellTab _tab = ShellTab.walk;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: _diaryLock.onPaused,
      onResume: _onResume,
    );
    backgroundChannel.setMethodCallHandler(_onBackgroundCall);
    _diaryLock.start();
    // 앱 시작 청소는 화면을 막지 않는다. 실패해도 다음 시작에 다시 한다.
    unawaited(getIt<DiaryUseCase>().cleanOrphans().catchError((Object _) {}));
    _alarms.load();
    _refresh();
  }

  void _onResume() {
    _diaryLock.onResumed();
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
    _holidaySettings.close();
    _diaryLock.close();
    _diarySettings.close();
    super.dispose();
  }

  /// 편집 · 울림 화면이 닫혔다 — 알람이 바뀌었거나 권한을 허용했을 수 있다.
  /// 알림 버튼으로 울림을 끈 경우에도 여기로 오므로 예약부터 다시 채운다.
  @override
  void didPopNext() => _refresh();

  /// 시작 · 복귀. 예약을 채운 뒤(지난 1회성이 꺼진 뒤) 목록을 읽는다.
  ///
  /// 그 앞에 헤드리스 엔진의 일(미리 알림 [이번만 끄기] 등)이 끝나기를 기다린다 — 알림을 누르고
  /// 바로 앱을 열면, 헤드리스가 `skippedAt` 을 쓰기 직전 상태로 sync 해 건너뛴 회차를 다시 걸 수 있다.
  /// 네이티브 일(`resync` · `reminderAction`)은 기다리지 않는다 — 디스패처가 그 일을 돌리는 중이다.
  ///
  /// 홈 화면 위젯을 눌러 열었으면(시작 · 복귀) 먼저 알람 탭으로 바꾼다.
  Future<void> _refresh() async {
    await _openFromHomeWidget();
    await awaitBackgroundIdle();
    await _reload(_alarmUseCase.sync);
  }

  Future<void> _reload(Future<void> Function() reschedule) async {
    _permissions.check();
    try {
      // 공휴일 캐시(폰 캘린더)는 하루 한 번만 실제로 읽는다 — 시작 · 하루 sync 때 갱신된다.
      // 실패해도 예약은 채운다(지난 캐시나 내장 표로 판정).
      await _holidays.refresh();
    } on Object {
      // refresh 는 던지지 않지만, 던져도 알람 예약을 막지 않는다.
    }
    try {
      await reschedule();
    } on Object {
      // 부르는 쪽이 기다리지 않는다(시작 · 복귀 · 화면 복귀) — 예외를 올리면 잡을 곳이 없다.
      // 예약은 다음 복귀에 다시 채우고, 목록은 저장된 대로 보인다.
    }
    await _alarms.load();
    // 공휴일 출처는 위 캐시 갱신 뒤에 읽는다. 시스템 설정에서 캘린더를 허용하고 돌아왔으면
    // 여기서 다시 읽고 예약을 맞춘다.
    await _holidaySettings.check();
  }

  /// 네이티브 `BackgroundDispatcher` 가 앱이 떠 있을 때 부른다.
  ///
  /// - `resync`: 시간대가 바뀌었거나 하루 한 번 작업이다 — 지금 시간대의 벽시계로 예약을 다시 걸고
  ///   ([AlarmUseCase.timeZoneChanged] 는 시간대가 그대로면 같은 예약을 다시 걸 뿐이다) 목록을
  ///   읽은 뒤 응답한다.
  /// - `reminderAction`(`{action: 'skip', packageId}`): 미리 알림의 [이번만 끄기] · [다음 알람
  ///   건너뛰기] — 그 회차를 건너뛰고 목록을 읽은 뒤 성공 여부로 응답한다. `false` 면 네이티브가
  ///   알림을 남겨 다시 누를 수 있게 한다.
  Future<Object?> _onBackgroundCall(MethodCall call) async {
    switch (call.method) {
      case 'resync':
        await _reload(_alarmUseCase.timeZoneChanged);
        return null;
      case 'reminderAction':
        final packageId = switch (call.arguments) {
          {'action': 'skip', 'packageId': final int id} => id,
          _ => throw PlatformException(
            code: 'bad_args',
            message: '${call.arguments}',
          ),
        };
        var ok = false;
        await _reload(() async {
          await _alarmUseCase.skipOccurrence(packageId);
          ok = true;
        });
        return ok;
      default:
        throw MissingPluginException();
    }
  }

  Future<void> _openFromHomeWidget() async {
    final bool launched;
    try {
      launched = await _homeWidget.takeLaunch();
    } on Object {
      return;
    }
    if (launched && mounted) _select(ShellTab.alarm);
  }

  void _select(ShellTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _alarms),
        BlocProvider.value(value: _permissions),
        BlocProvider.value(value: _holidaySettings),
        BlocProvider.value(value: _diaryLock),
        BlocProvider.value(value: _diarySettings),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _tab.index,
          children: [
            AlarmListPage(onOpenSettings: () => _select(ShellTab.settings)),
            WalkHomePage(active: _tab == ShellTab.walk),
            DiaryTab(active: _tab == ShellTab.diary),
            CommuteTab(active: _tab == ShellTab.commute),
            SettingsPage(active: _tab == ShellTab.settings),
          ],
        ),
        // 일기 ＋ 는 탭이 아니라 여기 둔다 — 스낵바가 뜨는 이 Scaffold 에 있어야 위로 비킨다.
        floatingActionButton: _tab == ShellTab.diary
            ? const DiaryNewEntryButton()
            : null,
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
              icon: const Icon(Icons.book_outlined),
              selectedIcon: const Icon(Icons.book),
              label: l10n.walkShellTabDiary,
            ),
            NavigationDestination(
              icon: const Icon(Icons.directions_subway_outlined),
              selectedIcon: const Icon(Icons.directions_subway),
              label: l10n.walkShellTabCommute,
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
