import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';

/// 사용자 아바타의 공통 표현.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.nickname,
    this.imageUrl,
    this.imageBytes,
    this.radius = 36,
    super.key,
  });

  final String nickname;
  final String? imageUrl;

  /// 아직 업로드하지 않은 로컬 이미지. 있으면 [imageUrl] 보다 우선한다.
  ///
  /// 사진을 고른 직후 미리보기를 보여주되, 저장 전까지는 Storage 에 아무것도
  /// 올리지 않기 위한 통로다.
  final Uint8List? imageBytes;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedUrl = imageUrl?.trim();
    final bytes = imageBytes;
    final foregroundImage = switch (bytes) {
      final Uint8List value => MemoryImage(value) as ImageProvider<Object>,
      null =>
        trimmedUrl != null && trimmedUrl.isNotEmpty
            ? NetworkImage(trimmedUrl)
            : null,
    };
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().characters.first;

    return Semantics(
      image: true,
      label: AppLocalizations.of(context).avatarSemanticsLabel(nickname),
      child: CircleAvatar(
        radius: radius,
        foregroundImage: foregroundImage,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Text(initial, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
