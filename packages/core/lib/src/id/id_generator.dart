import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// 앱이 직접 만들어야 하는 식별자의 출처.
///
/// 행 id 는 대부분 DB 가 `gen_random_uuid()` 로 채운다. 앱이 id 를 먼저 알아야
/// 하는 경우 — 행을 만들기 전에 Storage 경로를 정해야 할 때처럼 — 여기서 받는다.
///
/// 데이터소스가 생성 방법을 직접 들고 있지 않고 주입받는 이유는 테스트다.
/// 가짜를 끼우면 만들어지는 경로를 단언할 수 있다.
@lazySingleton
class IdGenerator {
  const IdGenerator(this._uuid);

  final Uuid _uuid;

  String newId() => _uuid.v4();
}
