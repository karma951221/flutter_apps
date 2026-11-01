import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import 'chat_vendor_icon.dart';

part 'model_chip.freezed.dart';

/// 칩 하나에 필요한 값(ChatState · ChatSettingsState 가 같이 만든다).
@freezed
class ModelChipData with _$ModelChipData {
  @override
  final ChatVendor vendor;

  /// 표시 이름.
  @override
  final String label;

  /// 빠른 출력이 켜져 요청에 실린다(번개).
  @override
  final bool fastMode;

  /// 지금 모델보다 늦게 나온 안 본 모델이 있다(점).
  @override
  final bool hasNewer;

  const ModelChipData({
    required this.vendor,
    required this.label,
    this.fastMode = false,
    this.hasNewer = false,
  });

  /// [choice] 의 지금 모델로 만든 칩. 모델이 없으면(목록 없음 · 미연결) null.
  static ModelChipData? of(ChatModelChoice choice) {
    final vendor = choice.vendor;
    final info = choice.currentInfo;
    if (vendor == null || info == null) return null;
    return ModelChipData(
      vendor: vendor,
      label: info.displayName,
      fastMode: choice.fastModeOn,
      hasNewer: choice.hasUnseenNewer,
    );
  }
}

/// 앱바 아래 모델 칩: 벤더 아이콘(작게) + 이름 + (빠른 출력이면 번개) + ▾.
/// 새 모델이 있으면 오른쪽 위에 점.
class ModelChip extends StatelessWidget {
  const ModelChip({required this.data, required this.onPressed, super.key});

  final ModelChipData data;

  /// null 이면 비활성(답을 받는 중).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 칩 라벨 줄에 맞춘 아이콘 크기 — 아이콘 크기 토큰이 없어 글자 토큰(titleMedium)을 따른다.
    // 기본(24)이면 앱바 아래 한 줄 칩에서 글자보다 커 보인다.
    final iconSize = Theme.of(context).textTheme.titleMedium?.fontSize;
    final chip = ActionChip(
      key: const Key('chat-model-chip'),
      tooltip: l10n.walkChatModelChipTooltip,
      visualDensity: VisualDensity.compact,
      avatar: ChatVendorIcon(data.vendor, size: iconSize),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(data.label, overflow: TextOverflow.ellipsis)),
          if (data.fastMode) Icon(Icons.bolt, size: iconSize),
          Icon(Icons.arrow_drop_down, size: iconSize),
        ],
      ),
      onPressed: onPressed,
    );
    if (!data.hasNewer) return chip;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        chip,
        PositionedDirectional(
          top: 0,
          end: 0,
          child: Semantics(
            container: true,
            label: l10n.walkChatModelNewerAvailable,
            child: const Badge(key: Key('chat-model-chip-dot')),
          ),
        ),
      ],
    );
  }
}
