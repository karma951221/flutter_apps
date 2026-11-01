import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_vendor.dart';

/// 공식 로고 자산 하나. 브랜드 가이드 확인(K1)을 마친 것만 [ChatVendorIcon.confirmedLogos] 에 넣는다.
final class ChatVendorLogo {
  const ChatVendorLogo(this.assetPath, {this.tintable = false});

  /// 예: 'assets/chat/vendors/anthropic.svg'
  final String assetPath;

  /// 가이드가 단색화를 허용하면 true — colorScheme.onSurface 로 칠해 라이트 · 다크 모두 맞춘다.
  final bool tintable;
}

/// 벤더 로고(Q9). 설정 연결 행 · ③ 의 모델 칩이 같이 쓴다.
/// 로고가 확인 전이거나 자산을 읽지 못하면 벤더 이름 첫 글자 원형(모노그램).
class ChatVendorIcon extends StatelessWidget {
  const ChatVendorIcon(
    this.vendor, {
    this.size,
    @visibleForTesting this.logos = confirmedLogos,
    super.key,
  });

  final ChatVendor vendor;

  /// null 이면 IconTheme.of(context).size.
  final double? size;

  /// 그릴 로고 맵. 앱에서는 늘 [confirmedLogos], 테스트만 바꾼다.
  final Map<ChatVendor, ChatVendorLogo> logos;

  /// K1 확인 전에는 비어 있다. 확인 뒤 한 줄씩 더한다.
  static const Map<ChatVendor, ChatVendorLogo> confirmedLogos = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = chatVendorName(l10n, vendor);
    final side = size ?? IconTheme.of(context).size ?? 24;
    final logo = logos[vendor];
    final Widget mark = logo == null
        ? _Monogram(letter: name[0], size: side)
        : SvgPicture.asset(
            logo.assetPath,
            width: side,
            height: side,
            colorFilter: logo.tintable
                ? ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  )
                : null,
            errorBuilder: (_, _, _) => _Monogram(letter: name[0], size: side),
          );
    return Semantics(
      label: name,
      child: ExcludeSemantics(
        child: SizedBox.square(dimension: side, child: mark),
      ),
    );
  }
}

/// 벤더 이름 첫 글자를 담은 원.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.letter, required this.size});

  final String letter;
  final double size;

  /// 글자 크기 / 원 지름. 아이콘 크기에 비례하는 계산이라 타이포 토큰 대신 비율로 둔다.
  static const _letterRatio = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.secondaryContainer,
        ),
        child: Center(
          child: Text(
            letter,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSecondaryContainer,
              fontSize: size * _letterRatio,
            ),
          ),
        ),
      ),
    );
  }
}

/// 벤더 표시 이름(제품). 요금 경고 · 연결 행 · 스낵바가 쓴다. anthropic → 'Claude'
String chatVendorName(AppLocalizations l10n, ChatVendor vendor) =>
    switch (vendor) {
      ChatVendor.anthropic => l10n.walkChatVendorClaude,
      ChatVendor.openai => l10n.walkChatVendorGpt,
    };

/// 벤더 회사 이름. anthropic → 'Anthropic'
String chatVendorCompany(AppLocalizations l10n, ChatVendor vendor) =>
    switch (vendor) {
      ChatVendor.anthropic => l10n.walkChatVendorAnthropic,
      ChatVendor.openai => l10n.walkChatVendorOpenAi,
    };
