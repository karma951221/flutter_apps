import 'package:flutter/rendering.dart';

/// 모서리 토큰. 역할마다 다르다 — 모든 모서리를 12 로 통일하지 않는다(design.md Shapes).
abstract final class PawlogRadius {
  /// 사진 · 지도 썸네일 — 인화한 사진처럼 거의 각지게.
  static const photo = 4.0;

  /// 입력칸 · 배너.
  static const control = 12.0;

  /// 바텀 시트 · 지도 위 시트 상단.
  static const sheet = 20.0;

  /// 주 버튼 · 토글 · 칩 — 알약.
  static const full = 9999.0;

  static const photoAll = BorderRadius.all(Radius.circular(photo));
  static const controlAll = BorderRadius.all(Radius.circular(control));
  static const sheetAll = BorderRadius.all(Radius.circular(sheet));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
  static const fullAll = BorderRadius.all(Radius.circular(full));
}
