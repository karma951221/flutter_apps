import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 Freezed 모델은 생성자 컨벤션을 지킨다', () {
    final sourceDirectory = Directory('lib');
    final modelFiles = sourceDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) =>
              !file.path.endsWith('.freezed.dart') &&
              !file.path.endsWith('.g.dart'),
        )
        .where((file) => file.readAsStringSync().contains('@freezed'));

    for (final file in modelFiles) {
      final source = file.readAsStringSync();
      // CursorPage<T> 처럼 타입 매개변수를 가진 모델도 대상이다.
      final classMatch = RegExp(
        r'(?:abstract\s+|sealed\s+)?class\s+(\w+)(?:<[^>]+>)?\s+with\s+_\$',
      ).firstMatch(source);
      expect(
        classMatch,
        isNotNull,
        reason: '${file.path}: @freezed 모델 클래스를 찾을 수 없습니다.',
      );

      final className = classMatch!.group(1)!;
      final isUnion = source.contains('sealed class $className');

      if (isUnion) {
        expect(
          source,
          contains('const factory $className.'),
          reason: '${file.path}: sealed union은 named factory case가 필요합니다.',
        );
      } else {
        expect(
          source,
          isNot(contains('const factory $className')),
          reason: '${file.path}: Freezed factory constructor는 사용할 수 없습니다.',
        );
        expect(
          source,
          contains('const $className('),
          reason: '${file.path}: $className canonical constructor가 필요합니다.',
        );
      }
    }
  });
}
