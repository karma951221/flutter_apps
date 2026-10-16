import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/photo/repository/photo_storage.dart';

void main() {
  for (final path in ['a.jpg', 'dir/a.jpg']) {
    test('"$path" 는 안전하다', () => expect(isSafePhotoPath(path), isTrue));
  }

  for (final path in [
    r'C:\x',
    'C:/x',
    'a//b',
    'a/',
    './a',
    'a/./b',
    r'a\..\b',
    'a\u0000b',
    '',
    '/abs',
    '../a',
  ]) {
    test('"$path" 는 거부한다', () => expect(isSafePhotoPath(path), isFalse));
  }
}
