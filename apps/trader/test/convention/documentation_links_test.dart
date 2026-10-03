import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _repoRoot = '../..';

/// 공통 문서(`docs/`), 앱별 문서(`apps/<app>/docs/`), 에이전트 가이드(`CLAUDE.md`).
List<File> _markdownFiles() {
  final directories = [
    Directory('$_repoRoot/docs'),
    ...Directory('$_repoRoot/apps')
        .listSync()
        .whereType<Directory>()
        .map((app) => Directory('${app.path}/docs'))
        .where((docs) => docs.existsSync()),
  ];
  return [
    for (final directory in directories)
      ...directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md')),
    File('$_repoRoot/CLAUDE.md'),
  ];
}

void main() {
  test('앱별 문서 폴더가 검사 대상에 들어 있다', () {
    final paths = _markdownFiles().map((file) => file.path).toList();

    expect(paths, contains(endsWith('apps/trader/docs/README.md')));
    expect(paths, contains(endsWith('apps/commute/docs/README.md')));
    expect(paths, contains(endsWith('apps/pawlog/docs/README.md')));
  });

  test('문서의 로컬 Markdown 링크는 존재하는 대상을 가리킨다', () {
    final linkPattern = RegExp(r'\[[^\]]*\]\(([^)]+)\)');

    for (final file in _markdownFiles()) {
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
