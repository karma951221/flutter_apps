import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('commute 앱은 트레이더 feature 패키지와 Supabase 를 의존하지 않는다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = pubspec
        .split('dependencies:')[1]
        .split('dev_dependencies:')[0];

    expect(
      RegExp(r'^\s+feature_', multiLine: true).hasMatch(dependencies),
      isFalse,
    );
    expect(dependencies, isNot(contains('supabase_flutter:')));
  });

  test('data · domain · presentation 은 go_router 를 모른다 — 페이지는 콜백을 받는다', () {
    final offenders = ['lib/data', 'lib/domain', 'lib/presentation']
        .expand((path) => Directory(path).listSync(recursive: true))
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => file.readAsStringSync().contains('package:go_router'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
