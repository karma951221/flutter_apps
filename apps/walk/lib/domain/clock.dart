import 'package:injectable/injectable.dart';

/// 테스트가 "오늘"을 고정할 수 있게 현재 시각을 주입한다.
@lazySingleton
class Clock {
  DateTime now() => DateTime.now();
}
