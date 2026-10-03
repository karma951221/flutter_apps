import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/app/router/dogs_redirect.dart';

void main() {
  test('반려견이 없으면 홈에서 등록 화면으로 보낸다', () {
    final redirect = DogsRedirect(hasDogs: false);

    expect(redirect.resolve(PawlogPaths.feed), PawlogPaths.newDog);
    expect(redirect.resolve(PawlogPaths.activeWalk), PawlogPaths.newDog);
  });

  test('/dogs 아래 경로는 그대로 둔다', () {
    final redirect = DogsRedirect(hasDogs: false);

    expect(redirect.resolve(PawlogPaths.newDog), isNull);
    expect(redirect.resolve(PawlogPaths.dogs), isNull);
    expect(redirect.resolve(PawlogPaths.dog('a')), isNull);
  });

  test('markHasDogs 뒤에는 홈을 허용한다', () {
    final redirect = DogsRedirect(hasDogs: false);

    redirect.markHasDogs();

    expect(redirect.resolve(PawlogPaths.feed), isNull);
  });

  test('반려견이 있으면 아무 데도 보내지 않는다', () {
    final redirect = DogsRedirect(hasDogs: true);

    expect(redirect.resolve(PawlogPaths.feed), isNull);
    expect(redirect.resolve(PawlogPaths.newDog), isNull);
  });
}
