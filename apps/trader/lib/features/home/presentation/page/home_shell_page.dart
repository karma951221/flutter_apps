import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:core/core.dart';
import 'package:l10n/l10n.dart';
import 'package:feature_chat/feature_chat.dart';
import 'package:feature_feed/feature_feed.dart';
import '../../../profile/presentation/page/profile_page.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_trade/feature_trade.dart';

/// 하단 내비게이션을 가진 홈 셸.
///
/// 탭 본문을 [IndexedStack] 으로 살려 두는 이유는 탭을 오갈 때 **피드의 스크롤
/// 위치와 읽어둔 페이지를 잃지 않기 위해서**다. 탭마다 화면을 다시 만들면 커서
/// 페이지네이션으로 쌓아 둔 목록이 매번 첫 페이지로 돌아간다.
///
/// go_router 의 `StatefulShellRoute` 를 쓰지 않는다. 탭 안에서 더 깊이 들어가는
/// 흐름(댓글 · 게시물 편집 · 프로필 편집 · 채팅방)은 셸 **위에** 얹는 편이
/// 단순하다. 탭별 딥링크가 필요해지면 그때 셸 라우트로 옮긴다.
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  /// 처음 보이는 탭. 0 은 모의투자다.
  int _index = 0;

  /// 채팅 탭 배지를 위해 셸이 방 목록 cubit 을 소유한다.
  ///
  /// 탭 본문(`ChatRoomListPage`)이 자기 cubit 을 만들면 배지가 그 화면 안에
  /// 갇혀서 다른 탭에 있을 때 숫자를 알 수 없다. 그래서 여기서 만들어 아래로
  /// 내려준다 — 목록 화면은 이 인스턴스를 **쓰기만** 한다.
  late final ChatRoomListCubit _chatRooms;

  @override
  void initState() {
    super.initState();
    _chatRooms = getIt<ChatRoomListCubit>()..load();
  }

  @override
  void dispose() {
    _chatRooms.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <_HomeTab>[
      // 첫 탭이 모의투자다. 앱을 여는 이유가 여기 있고, 피드는 그 결과를
      // 나누는 자리다.
      _HomeTab(
        label: l10n.homeTabTrade,
        icon: Icons.candlestick_chart_outlined,
        selectedIcon: Icons.candlestick_chart,
        body: const TradeHomePage(),
      ),
      _HomeTab(
        label: l10n.homeTabFeed,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        body: const FeedPage(),
      ),
      _HomeTab(
        label: l10n.homeTabChat,
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        body: const ChatRoomListPage(),
        showsUnreadBadge: true,
      ),
      _HomeTab(
        label: l10n.homeTabProfile,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        // userId 를 주지 않으면 세션 사용자의 프로필이다.
        body: const ProfilePage(),
      ),
      _HomeTab(
        label: l10n.homeTabSettings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        body: const SettingsPage(),
      ),
    ];

    return BlocProvider.value(
      value: _chatRooms,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [for (final tab in tabs) tab.body],
        ),
        bottomNavigationBar: BlocBuilder<ChatRoomListCubit, ChatRoomListState>(
          builder: (context, chatState) => NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (next) => setState(() => _index = next),
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  // v1 의 배지는 방 목록을 다시 읽을 때 갱신된다. 방 밖에서의
                  // 상시 갱신은 푸시 알림과 함께 4단계에서 다룬다.
                  //
                  // 배지가 붙는 자리는 탭이 스스로 안다 — 탭 순서가 바뀌어도
                  // 숫자가 엉뚱한 아이콘으로 옮겨가지 않는다.
                  icon: _withBadge(
                    Icon(tab.icon),
                    tab.showsUnreadBadge ? chatState.totalUnread : 0,
                  ),
                  selectedIcon: _withBadge(
                    Icon(tab.selectedIcon),
                    tab.showsUnreadBadge ? chatState.totalUnread : 0,
                  ),
                  label: tab.label,
                  tooltip: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withBadge(Widget icon, int count) =>
      count > 0 ? Badge.count(count: count, child: icon) : icon;
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.body,
    this.showsUnreadBadge = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget body;

  /// 안읽음 개수를 아이콘에 얹을지. 지금은 채팅 탭 하나뿐이다.
  final bool showsUnreadBadge;
}
