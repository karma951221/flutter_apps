import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 모두의 산책(`/community`) — 이번 조각은 자리만 잡는다. 목록 · 좋아요 · 로그인 메뉴는
/// 다음 조각(W5 Task 4)이 채운다.
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkSocialTitle)),
      body: Center(child: AppPlaceholder(message: l10n.walkSocialEmpty)),
    );
  }
}
