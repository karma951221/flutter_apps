import 'package:flutter/material.dart';

/// 상태 라벨의 성격 — 됨(primary) · 보통(onSurfaceVariant) · 조치 필요(error).
enum StatusTone { ok, neutral, attention }

/// 설정 행 오른쪽의 짧은 상태 글자 — '허용됨' · '연결됨' · '권한 필요'.
///
/// 권한 · 키 · 백업 화면이 각자 다른 글자 크기와 색으로 그리던 것을 하나로 모았다.
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.text, {this.tone = StatusTone.neutral, super.key});

  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: switch (tone) {
          StatusTone.ok => scheme.primary,
          StatusTone.neutral => scheme.onSurfaceVariant,
          StatusTone.attention => scheme.error,
        },
      ),
    );
  }
}
