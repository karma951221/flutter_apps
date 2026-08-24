import 'package:flutter/material.dart';

import '../../../feed/presentation/page/feed_page.dart';
import '../../../profile/presentation/page/profile_page.dart';
import '../../../settings/presentation/page/settings_page.dart';

/// 하단 내비게이션을 가진 홈 셸.
///
/// 탭 본문을 [IndexedStack] 으로 살려 두는 이유는 탭을 오갈 때 **피드의 스크롤
/// 위치와 읽어둔 페이지를 잃지 않기 위해서**다. 탭마다 화면을 다시 만들면 커서
/// 페이지네이션으로 쌓아 둔 목록이 매번 첫 페이지로 돌아간다.
///
/// go_router 의 `StatefulShellRoute` 를 쓰지 않는다. 탭이 셋뿐이고 탭 안에서
/// 더 깊이 들어가는 흐름(댓글 · 게시물 편집 · 프로필 편집)은 셸 **위에** 얹는
/// 편이 단순하다. 탭별 딥링크가 필요해지면 그때 셸 라우트로 옮긴다.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _index = 0;

  static const _tabs = <_HomeTab>[
    _HomeTab(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      body: FeedPage(),
    ),
    _HomeTab(
      label: '프로필',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      // userId 를 주지 않으면 세션 사용자의 프로필이다.
      body: ProfilePage(),
    ),
    _HomeTab(
      label: '설정',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      body: SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [for (final tab in _tabs) tab.body],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (next) => setState(() => _index = next),
      destinations: [
        for (final tab in _tabs)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: tab.label,
            tooltip: tab.label,
          ),
      ],
    ),
  );
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;
}
