import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';

import '../theme/app_motion.dart';

/// 사용자 아바타의 공통 표현.
///
/// [fadeInImage] 를 켜면 이미지가 로드되는 순간 이니셜 위로 페이드인한다. 꺼져
/// 있으면 이니셜에서 사진으로 툭 바뀐다. 이미 캐시에 있어 동기로 그려지는
/// 이미지는 켜 있어도 페이드 없이 바로 그린다 — 스크롤로 다시 보일 때마다
/// 깜빡이면 오히려 어지럽다.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.nickname,
    this.imageUrl,
    this.imageBytes,
    this.imageFile,
    this.radius = 36,
    this.fadeInImage = false,
    super.key,
  });

  final String nickname;
  final String? imageUrl;

  /// 아직 업로드하지 않은 로컬 이미지. 있으면 [imageUrl] 보다 우선한다.
  ///
  /// 사진을 고른 직후 미리보기를 보여주되, 저장 전까지는 Storage 에 아무것도
  /// 올리지 않기 위한 통로다.
  final Uint8List? imageBytes;

  /// 기기에 저장된 이미지 파일. [imageBytes] 다음, [imageUrl] 앞의 우선순위다.
  final File? imageFile;

  final double radius;

  /// 이미지가 로드되면 이니셜 위로 페이드인할지. 기본 false.
  ///
  /// 켜도 시스템 '애니메이션 줄이기'면 기존과 같이 바로 바꾼다.
  final bool fadeInImage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedUrl = imageUrl?.trim();
    final bytes = imageBytes;
    final file = imageFile;
    final foregroundImage = switch ((bytes, file)) {
      (final Uint8List value, _) => MemoryImage(value) as ImageProvider<Object>,
      (null, final File value) => FileImage(value),
      (null, null) =>
        trimmedUrl != null && trimmedUrl.isNotEmpty
            ? NetworkImage(trimmedUrl)
            : null,
    };
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().characters.first;

    final initialText = Text(
      initial,
      style: Theme.of(context).textTheme.headlineSmall,
    );
    final fade =
        fadeInImage && foregroundImage != null && AppMotion.enabled(context);

    return Semantics(
      image: true,
      label: AppLocalizations.of(context).avatarSemanticsLabel(nickname),
      child: fade
          ? _FadingAvatar(
              radius: radius,
              image: foregroundImage,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              initial: initialText,
            )
          : CircleAvatar(
              radius: radius,
              foregroundImage: foregroundImage,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: initialText,
            ),
    );
  }
}

/// 이니셜 원 위에 사진을 겹쳐 첫 프레임에 페이드인한다.
///
/// `CircleAvatar.foregroundImage` 는 로드 시점을 알려주지 않아 페이드를 걸 수
/// 없다. 그래서 같은 원을 그리되 사진은 `Image.frameBuilder` 로 직접 그린다.
class _FadingAvatar extends StatelessWidget {
  const _FadingAvatar({
    required this.radius,
    required this.image,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.initial,
  });

  final double radius;
  final ImageProvider<Object> image;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget initial;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: radius * 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            child: initial,
          ),
          ClipOval(
            child: Image(
              image: image,
              fit: BoxFit.cover,
              // 이름은 바깥 Semantics 가 이미 읽는다.
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                  child: child,
                );
              },
              // 실패하면 이니셜을 그대로 둔다 — `CircleAvatar` 가 사진을 못 그릴
              // 때 배경과 이니셜만 남기는 것과 같은 모습.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
