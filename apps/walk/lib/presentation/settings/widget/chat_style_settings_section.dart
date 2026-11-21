import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_style_settings.dart';
import '../../chat/widget/chat_tone_tile.dart';

/// 물어보기 설정의 '답' 묶음 — 말투(대화 설정 시트와 같은 행) · 그림 만들기 스위치.
/// [style] 을 주지 않으면 DI 의 것을 쓴다.
class ChatStyleSettingsSection extends StatefulWidget {
  const ChatStyleSettingsSection({this.style, super.key});

  final ChatStyleSettings? style;

  @override
  State<ChatStyleSettingsSection> createState() =>
      _ChatStyleSettingsSectionState();
}

class _ChatStyleSettingsSectionState extends State<ChatStyleSettingsSection> {
  late final ChatStyleSettings _style =
      widget.style ?? getIt<ChatStyleSettings>();

  Future<void> _setImageGeneration(bool on) async {
    await _style.setImageGeneration(on);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(l10n.walkChatAnswerSection),
        ChatToneTile(style: _style),
        AppSwitchTile(
          switchKey: const Key('chat-settings-image-generation'),
          leading: const Icon(Icons.image_outlined),
          title: Text(l10n.walkChatImageGenTitle),
          subtitle: Text(l10n.walkChatImageGenHint),
          value: _style.imageGeneration,
          onChanged: (on) => unawaited(_setImageGeneration(on)),
        ),
      ],
    );
  }
}
