import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../widget/chat_settings_section.dart';

/// 물어보기 설정 — API 키. 잠금 아래 화면이다(`openSettings` 가 `pushDiaryRoute` 로 연다).
class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkChatSettingsTitle)),
      body: ListView(children: const [ChatSettingsSection()]),
    );
  }
}
