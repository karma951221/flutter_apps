import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:l10n/l10n.dart';

/// 사용자 아바타의 공통 표현.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.nickname,
    this.imageUrl,
    this.imageBytes,
    this.imageFile,
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

  /// 기기에 저장된 이미지 파일. [imageBytes] 다음, [imageUrl] 앞의 우선순위다.
  final File? imageFile;

  final double radius;

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
