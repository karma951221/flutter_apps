import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

/// 위로 올려 둔 채 답이 자랄 때 입력칸 위에 뜨는 [↓ 새 답]. AppButton.secondary 를 감싼다.
///
/// 목록 위에 떠 있으므로 라벨 폭만큼만 차지하고(테마의 꽉 찬 최소 너비를 풀어 준다),
/// 뒤의 말풍선이 비치지 않게 바탕을 칠한다. 스크린 리더에는 화살표 없이 '새 답' 버튼으로 읽힌다.
class ChatJumpToLatest extends StatelessWidget {
  const ChatJumpToLatest({required this.onPressed, super.key});

  final VoidCallback onPressed;

  /// 라벨 앞 아래 화살표.
  static const _arrow = '↓';

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).walkChatJumpToLatest;
    return Semantics(
      label: label,
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: AppButton.secondary(
        label: '$_arrow $label',
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, kMinInteractiveDimension),
          ),
          backgroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}
