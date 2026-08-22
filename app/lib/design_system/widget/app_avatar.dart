import 'package:flutter/material.dart';

/// 사용자 아바타의 공통 표현.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.nickname,
    this.imageUrl,
    this.radius = 36,
    super.key,
  });

  final String nickname;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trimmedUrl = imageUrl?.trim();
    final hasImage = trimmedUrl != null && trimmedUrl.isNotEmpty;
    final initial = nickname.trim().isEmpty
        ? '?'
        : nickname.trim().characters.first;

    return Semantics(
      image: true,
      label: '$nickname 프로필 사진',
      child: CircleAvatar(
        radius: radius,
        foregroundImage: hasImage ? NetworkImage(trimmedUrl) : null,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Text(initial, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
