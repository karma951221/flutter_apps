import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../alarm/page/alarm_list_page.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../map/page/map_tab.dart';
import '../../settings/open_settings.dart';
import '../../walk/page/walk_home_page.dart';
import '../widget/feature_menu.dart';

/// 도구 탭의 상단 탭. 순서가 `TabBar` 순서다.
enum ToolsSection { alarm, walk, map }

/// 도구 탭 — 알람 · 걷기 · 지도를 앱바 아래 상단 탭으로 묶는다.
///
/// 상단 탭은 눌러서만 바꾼다(밀기 없음).
///
/// 앱바는 하나라 actions 와 ⋮ 가 [section] 에 따라 바뀐다 — 알람이면 [AlarmPauseAction] 과
/// 알람 기록 · 알람 설정, 걷기면 걷기 설정, 지도면 지도 설정(일기 잠금 아래라 잠긴 동안은
/// 앱 설정만). 고른 상단 탭은 셸이 쥐고([section]) 사용자가
/// 바꾸면 [onSectionChanged] 로 알린다. 셸이 바꾸면(홈 화면 위젯으로 열림) 그쪽으로 넘어간다.
///
/// 셸의 `AlarmListCubit` · 설정 cubit 넷([openSettings]) · `DiaryLockCubit` · 지도 cubit 둘 아래에 둔다.
class ToolsTab extends StatefulWidget {
  const ToolsTab({
    required this.active,
    required this.section,
    required this.onSectionChanged,
    required this.onOpenAlarmSettings,
    super.key,
  });

  /// 셸에서 도구 탭이 보이는지. 셸 위에 다른 라우트가 얹혀 있으면 false 다.
  final bool active;

  /// 고른 상단 탭. 셸이 소유한다.
  final ToolsSection section;
  final ValueChanged<ToolsSection> onSectionChanged;

  /// 알람 권한 경고를 눌렀을 때 — [AlarmListPage.onOpenSettings] 로 넘긴다.
  final VoidCallback onOpenAlarmSettings;

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab>
    with SingleTickerProviderStateMixin {
  late final _controller = TabController(
    length: ToolsSection.values.length,
    initialIndex: widget.section.index,
    vsync: this,
  )..addListener(_onTabChanged);

  /// 사용자가 상단 탭을 눌렀다. 셸이 바꾼 것([didUpdateWidget])이면 이미 같다.
  void _onTabChanged() {
    final index = _controller.index;
    if (index != widget.section.index) {
      widget.onSectionChanged(ToolsSection.values[index]);
    }
  }

  @override
  void didUpdateWidget(ToolsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.index != widget.section.index) {
      _controller.animateTo(widget.section.index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = context.select<DiaryLockCubit, bool>(
      (c) => c.state is LockUnlocked,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walkShellTabTools),
        actions: switch (widget.section) {
          ToolsSection.alarm => [
            const AlarmPauseAction(),
            FeatureMenu(
              settings: SettingsTarget.alarm,
              entries: [
                FeatureMenuEntry(
                  key: const Key('menu-alarm-history'),
                  label: l10n.walkAlarmHistory,
                  icon: Icons.history,
                  onTap: () => openAlarmHistory(context),
                ),
              ],
            ),
          ],
          ToolsSection.walk => [
            const FeatureMenu(settings: SettingsTarget.walk),
          ],
          ToolsSection.map => [
            FeatureMenu(
              settings: SettingsTarget.map,
              showFeatureSettings: unlocked,
            ),
          ],
        },
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(text: l10n.walkToolsTabAlarm),
            Tab(text: l10n.walkToolsTabWalk),
            Tab(text: l10n.walkToolsTabMap),
          ],
        ),
      ),
      // 밀기로는 넘기지 않는다 — 걷기 화면 안에 자기 상단 탭(오늘 | 기록)이 있고 지도는 끌어 움직여
      // 가로 밀기가 겹친다.
      body: TabBarView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _KeepAlive(
            child: AlarmListPage(onOpenSettings: widget.onOpenAlarmSettings),
          ),
          _KeepAlive(
            child: WalkHomePage(
              active: widget.active && widget.section == ToolsSection.walk,
            ),
          ),
          _KeepAlive(
            child: MapTab(
              active: widget.active && widget.section == ToolsSection.map,
            ),
          ),
        ],
      ),
    );
  }
}

/// 상단 탭을 넘겨도 화면 상태(걷기 cubit · 스크롤)를 버리지 않는다 — `TabBarView` 는
/// 보이지 않는 페이지를 기본으로 버린다.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
