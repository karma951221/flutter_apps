import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 하단 바([child])의 아래 여백을 시스템 내비 높이(`viewPadding.bottom`) 아래로 내려가지 않게 한다.
///
/// `MediaQuery.padding` 은 IME inset 만큼 깎인 값이라, 키보드가 닫혔는데 엔진의 `viewInsets` 가
/// 키보드 높이로 남으면(stale) 0 이 되어 탭바가 안드로이드 시스템 내비 버튼 밑으로 그려진다.
/// `viewPadding` 은 inset 에 먹히지 않는다. 키보드가 정말 열렸을 때는 탭바가 키보드 뒤에 있어
/// (Scaffold 는 하단 바를 올리지 않는다) 보이는 동작이 같다.
class SystemBarBottomPadding extends StatelessWidget {
  const SystemBarBottomPadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = math.max(media.padding.bottom, media.viewPadding.bottom);
    if (bottom == media.padding.bottom) return child;
    return MediaQuery(
      data: media.copyWith(padding: media.padding.copyWith(bottom: bottom)),
      child: child,
    );
  }
}
