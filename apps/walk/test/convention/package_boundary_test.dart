import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walk 앱은 트레이더 feature 패키지와 Supabase 를 의존하지 않는다', () {
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
}
