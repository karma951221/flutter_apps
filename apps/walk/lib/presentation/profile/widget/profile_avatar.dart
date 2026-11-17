import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 프로필 아바타 — 사진이 있으면 사진, 없으면 이름 첫 글자([AppAvatar]).
/// 이름도 없으면 사람 아이콘이다(`AppAvatar` 는 빈 이름을 '?' 로 그린다).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    required this.photoPath,
    this.radius = 28,
    super.key,
  });

  final String name;
  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path == null && name.trim().isEmpty) {
      // AppAvatar 와 같은 원 · 색. 이니셜 대신 아이콘이라 CircleAvatar 를 직접 쓴다.
      final colors = Theme.of(context).colorScheme;
      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Icon(Icons.person_outline, size: radius),
      );
    }
    return AppAvatar(
      nickname: name,
      imageFile: path == null ? null : File(path),
      radius: radius,
    );
  }
}
