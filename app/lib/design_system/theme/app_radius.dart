import 'package:flutter/rendering.dart';

/// 모서리 토큰.
///
/// 화면에서 `BorderRadius.circular(n)` 을 직접 쓰지 않는다 (CLAUDE.md 규칙 5).
abstract final class AppRadius {
  /// 썸네일·작은 카드.
  static const sm = 8.0;

  /// 말풍선처럼 크게 둥근 것.
  static const lg = 18.0;

  /// 네 모서리에 [sm] 을 두른 값. `ClipRRect` 가 그대로 받는다.
  static const smAll = BorderRadius.all(Radius.circular(sm));

  /// 네 모서리에 [lg] 를 두른 값.
  static const lgAll = BorderRadius.all(Radius.circular(lg));
}
