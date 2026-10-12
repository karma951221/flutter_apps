import 'package:injectable/injectable.dart';

/// 미디어 선택 · 카메라로 나가는 동안 true. image_picker 호출부가 [run] 으로 감싼다.
///
/// 그동안 앱이 백그라운드로 가도 일기를 다시 잠그지 않는다(스펙 §7).
@lazySingleton
class MediaPickGuard {
  int _running = 0;

  bool get active => _running > 0;

  /// [pick] 이 끝날 때까지(던져도) [active] 를 켠다. 겹쳐 부르면 모두 끝나야 꺼진다.
  Future<T> run<T>(Future<T> Function() pick) async {
    _running++;
    try {
      return await pick();
    } finally {
      _running--;
    }
  }
}
