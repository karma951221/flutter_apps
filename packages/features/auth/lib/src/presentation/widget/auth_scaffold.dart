import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:design_system/design_system.dart';

/// 인증 화면 공통 뼈대.
///
/// 세 화면의 여백·최대 너비·스크롤 규칙을 한 곳에 둔다. 화면마다 따로 쓰면
/// 필드가 하나 늘어날 때마다 여백이 조금씩 달라진다.
///
/// 항상 스크롤 가능하게 둔 이유는 작은 화면에서 키보드가 올라오면 폼 높이가
/// 남는 공간을 넘기기 때문이다. 대신 내용이 짧을 때는 [Center] 로 세로 중앙에
/// 놓아 로그인 화면이 위쪽에 몰리지 않게 한다.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, this.showAppBar = false, super.key});

  final Widget child;

  /// 로그인에서 밀어 올린 화면은 돌아갈 길이 필요하다. 제목은 두지 않는다 —
  /// 화면 이름은 본문의 [AuthHeader] 가 맡고, 같은 문구를 두 번 보여주지 않는다.
  final bool showAppBar;

  /// 큰 화면에서 폼이 가로로 늘어지면 읽기 어렵다. 한 줄 길이를 제한한다.
  static const _maxContentWidth = 440.0;

  static const _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xl,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar() : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = math.max(
              0.0,
              constraints.maxHeight - _padding.vertical,
            );
            return SingleChildScrollView(
              padding: _padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Center(
                  // 화면보다 넓은 너비를 지정해도 SizedBox 가 부모 제약으로
                  // 잘라주므로 작은 화면에서 넘치지 않는다.
                  child: SizedBox(width: _maxContentWidth, child: child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
