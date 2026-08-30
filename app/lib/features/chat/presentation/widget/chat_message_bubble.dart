import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extension/date_time_format.dart';
import '../../../../design_system/theme/app_radius.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entity/chat_message.dart';
import '../../domain/usecase/chat_use_case.dart';

/// 대화 한 줄.
///
/// 공통 위젯으로 표현되지 않아 새로 만든다 — 좌우로 갈리는 정렬, 꼬리 없는
/// 둥근 모서리, 보내는 중·실패 표시가 이 화면에만 필요한 모양이다. 반복되면
/// 그때 `design_system/widget/` 승격을 검토한다 (CLAUDE.md 규칙 4).
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.isMine,
    required this.showSender,
    this.onRetry,
    this.onLongPress,
    super.key,
  });

  final ChatMessage message;
  final bool isMine;

  /// 같은 사람이 연달아 보냈으면 이름을 다시 적지 않는다.
  final bool showSender;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) return _SystemLine(message: message);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final background = isMine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final foreground = isMine ? scheme.onPrimaryContainer : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showSender && !isMine) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                message.senderNickname ?? '',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMine) _Meta(message: message, onRetry: onRetry),
              Flexible(
                child: GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: AppRadius.lgAll,
                    ),
                    child: switch (message.type) {
                      ChatMessageType.image => _BubbleImage(message: message),
                      _ => Text(
                        message.content ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    },
                  ),
                ),
              ),
              if (!isMine) _Meta(message: message, onRetry: onRetry),
            ],
          ),
          if (message.isFailed && onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.chatRetry),
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

/// 시각과 전송 상태. 버블 바깥에 작게 붙는다.
class _Meta extends StatelessWidget {
  const _Meta({required this.message, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: message.isFailed
          ? theme.colorScheme.error
          : theme.colorScheme.onSurfaceVariant,
    );

    final label = switch (message.delivery) {
      ChatMessageDelivery.pending => l10n.chatSending,
      ChatMessageDelivery.failed => l10n.chatSendFailedShort,
      ChatMessageDelivery.sent => message.createdAt.displayTimeOnly,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(label, style: style),
    );
  }
}

/// 비공개 버킷의 사진. 서명 URL 을 받아 와서 그린다.
///
/// 경로만으로는 그릴 수 없다 — `chat-images` 는 비공개라 방 참여자에게만
/// 한시적 URL 이 발급된다.
class _BubbleImage extends StatefulWidget {
  const _BubbleImage({required this.message});

  final ChatMessage message;

  @override
  State<_BubbleImage> createState() => _BubbleImageState();
}

class _BubbleImageState extends State<_BubbleImage> {
  String? _url;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final path = widget.message.imagePath;
    // 아직 올라가지 않은 낙관적 버블은 경로가 없다.
    if (path == null) return;

    final result = await getIt<ChatUseCase>().imageUrl(path);
    if (!mounted) return;
    result.when(
      ok: (url) => setState(() => _url = url),
      err: (_) => setState(() => _failed = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_failed) {
      return Text(
        l10n.chatImageLoadFailed,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final url = _url;
    if (url == null) {
      return const SizedBox(
        width: 160,
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: CachedNetworkImage(
        imageUrl: url,
        width: 220,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const SizedBox(width: 220, height: 160),
        errorWidget: (_, _, _) => Text(l10n.chatImageLoadFailed),
      ),
    );
  }
}

/// 입장·퇴장 안내. DB 는 키만 저장하고 문장은 여기서 만든다.
class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actor = message.content ?? '';

    final text = switch (message.systemEvent) {
      ChatSystemEvent.join => l10n.chatSystemJoined(actor),
      ChatSystemEvent.leave => l10n.chatSystemLeft(actor),
      // 앱이 모르는 사건 키다. 빈 줄을 남기느니 아무것도 그리지 않는다.
      null => '',
    };
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
