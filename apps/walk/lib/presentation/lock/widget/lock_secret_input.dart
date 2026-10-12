import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/lock/lock_config.dart';
import 'pattern_lock.dart';
import 'pin_pad.dart';

/// 잠금 방식에 맞는 입력(PIN 키패드 · 패턴). 결과는 비밀 문자열 하나로 넘긴다 —
/// PIN '1234', 패턴은 점 인덱스를 '-' 로 이은 '0-1-2-5'(건너뛴 점 포함).
class LockSecretInput extends StatelessWidget {
  const LockSecretInput({
    required this.method,
    required this.onSecret,
    this.enabled = true,
    this.error = false,
    super.key,
  });

  /// 입력의 최대 폭. 넓은 화면에서 키패드 · 격자가 지나치게 커지지 않게.
  static const maxWidth = AppSpacing.xl * 9;

  final LockMethod method;
  final ValueChanged<String> onSecret;
  final bool enabled;
  final bool error;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: maxWidth),
    child: switch (method) {
      LockMethod.pin => PinPad(
        onCompleted: onSecret,
        enabled: enabled,
        error: error,
      ),
      LockMethod.pattern => PatternLock(
        onCompleted: (dots) => onSecret(dots.join('-')),
        enabled: enabled,
      ),
    },
  );
}

/// 차단 안내. 차단 중이 아니면 null. 30초 차단은 남은 초(올림), 24시간 차단은 시간 · 분.
String? lockBlockedMessage(
  AppLocalizations l10n,
  Duration? blockedFor, {
  required bool longBlock,
}) {
  if (blockedFor == null) return null;
  if (longBlock) {
    return l10n.walkLockBlockedLong(
      blockedFor.inHours,
      blockedFor.inMinutes % Duration.minutesPerHour,
    );
  }
  final seconds =
      (blockedFor.inMilliseconds + Duration.millisecondsPerSecond - 1) ~/
      Duration.millisecondsPerSecond;
  return l10n.walkLockBlocked(seconds);
}

/// 잠금 화면 · 설정 화면 공통 배치: 제목(있으면) · 안내 · 상태(오류) 한 줄 · 입력 · 아래 행동.
class LockPromptLayout extends StatelessWidget {
  const LockPromptLayout({
    required this.prompt,
    required this.input,
    this.title,
    this.status,
    this.footer,
    super.key,
  });

  final String? title;
  final String prompt;

  /// 오류 · 차단 안내. 없어도 줄을 차지해 입력이 움직이지 않게 한다.
  final String? status;
  final Widget input;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    final footer = this.footer;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              prompt,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              status ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            input,
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              footer,
            ],
          ],
        ),
      ),
    );
  }
}
