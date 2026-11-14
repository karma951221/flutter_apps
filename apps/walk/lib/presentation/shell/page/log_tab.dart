import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../diary/page/diary_tab.dart';
import '../../lock/cubit/diary_lock_cubit.dart';
import '../../lock/cubit/diary_lock_state.dart';
import '../../map/page/map_tab.dart';
import '../../settings/open_settings.dart';
import '../widget/feature_menu.dart';
import 'tools_tab.dart';

/// 기록 탭의 상단 탭. 순서가 `TabBar` 순서다.
enum LogSection { diary, map }

/// 기록 탭 — 내 일상 기록(일기)과 다닌 곳(지도)을 앱바 아래 상단 탭으로 묶는다.
///
/// 상단 탭은 눌러서만 바꾼다(밀기 없음 — 지도는 끌어 움직인다).
///
/// 앱바는 하나라 actions 와 ⋮ 가 [section] 에 따라 바뀐다 — 일기면 🔍([DiarySearchAction]) 와
/// [DiaryMenu], 지도면 지도 설정. 둘 다 일기 잠금 아래라 잠긴 동안은 🔍 없이 앱 설정만 둔다.
/// 고른 상단 탭은 셸이 쥐고([section]) 사용자가 바꾸면 [onSectionChanged] 로 알린다. 셸이 바꾸면
/// (스토리 뷰어의 "지도로 보기") 그쪽으로 넘어간다.
///
/// 셸의 `DiaryLockCubit` · 설정 cubit([openSettings]) · 지도 cubit 둘 아래에 둔다.
class LogTab extends StatefulWidget {
  const LogTab({
    required this.selected,
    required this.section,
    required this.onSectionChanged,
    super.key,
  });

  /// 하단 탭이 기록인지 — 위에 얹힌 라우트와 무관하다. 일기 · 지도는 이것으로 다시 잠길 때 자기
  /// 팝업(새 스토리 · 스토리 고르기 · ⋮)을 닫을지 정한다. 팝업도 셸에는 얹힌 라우트다.
  final bool selected;

  /// 고른 상단 탭. 셸이 소유한다.
  final LogSection section;
  final ValueChanged<LogSection> onSectionChanged;

  @override
  State<LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<LogTab> with SingleTickerProviderStateMixin {
  late final _controller = TabController(
    length: LogSection.values.length,
    initialIndex: widget.section.index,
    vsync: this,
  )..addListener(_onTabChanged);

  /// 사용자가 상단 탭을 눌렀다. 셸이 바꾼 것([didUpdateWidget])이면 이미 같다.
  void _onTabChanged() {
    final index = _controller.index;
    if (index != widget.section.index) {
      widget.onSectionChanged(LogSection.values[index]);
    }
  }

  @override
  void didUpdateWidget(LogTab oldWidget) {
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
        title: Text(l10n.walkShellTabLog),
        actions: switch (widget.section) {
          LogSection.diary => [
            if (unlocked) const DiarySearchAction(),
            DiaryMenu(unlocked: unlocked),
          ],
          LogSection.map => [
            FeatureMenu(
              settings: SettingsTarget.map,
              showFeatureSettings: unlocked,
            ),
          ],
        },
        bottom: TabBar(
          controller: _controller,
          tabs: [
            Tab(text: l10n.walkShellTabDiary),
            Tab(text: l10n.walkLogTabMap),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          TabKeepAlive(
            child: DiaryTab(
              active: widget.selected && widget.section == LogSection.diary,
            ),
          ),
          TabKeepAlive(
            child: MapTab(
              active: widget.selected && widget.section == LogSection.map,
            ),
          ),
        ],
      ),
    );
  }
}
