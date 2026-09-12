import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('문서의 로컬 Markdown 링크는 존재하는 대상을 가리킨다', () {
    final docsDirectory = Directory('../../docs');
    final markdownFiles = docsDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'));
    final linkPattern = RegExp(r'\[[^\]]*\]\(([^)]+)\)');

    for (final file in markdownFiles) {
      final source = file.readAsStringSync();
      for (final match in linkPattern.allMatches(source)) {
        final target = match.group(1)!;
        if (target.startsWith('http') ||
            target.startsWith('mailto:') ||
            target.startsWith('#')) {
          continue;
        }

        final path = target.split('#').first;
        final resolved = File('${file.parent.path}/$path');
        final exists =
            resolved.existsSync() ||
            Directory('${file.parent.path}/$path').existsSync();
        expect(exists, isTrue, reason: '${file.path}: 깨진 링크 $target');
      }
    }
  });
}
