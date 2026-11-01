import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../widget/chat_history_settings_section.dart';
import '../widget/chat_settings_section.dart';

/// 물어보기 설정 — AI 연결 · 대화 기록. 잠금 아래 화면이다(`openSettings` 가 `pushDiaryRoute` 로 연다).
class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({this.highlightConnection = false, super.key});

  /// true 면 열린 뒤 연결 행을 강조한다(물어보기 탭의 연결 안내에서 올 때).
  final bool highlightConnection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkChatSettingsTitle)),
      body: ListView(
        children: [
          ChatSettingsSection(highlightConnection: highlightConnection),
          const ChatHistorySettingsSection(),
        ],
      ),
    );
  }
}
