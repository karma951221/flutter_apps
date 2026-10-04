import 'package:injectable/injectable.dart';

/// 현재 시각을 주입한다. 테스트는 이 클래스를 상속해 `now` 를 고정한다.
///
/// `CorePackageModule` 이 등록한다. 그 모듈을 쓰지 않는 앱(walk)은 자기
/// `RegisterModule` 에서 등록한다.
@lazySingleton
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}
