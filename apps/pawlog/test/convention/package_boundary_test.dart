import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature_walk는 허용된 패키지 경계를 넘지 않는다', () {
    final workspaceRoot = Directory.current.parent.parent;
    final pubspec = File(
      '${workspaceRoot.path}/packages/features/walk/pubspec.yaml',
    ).readAsStringSync();
    final dependencies = pubspec
        .split('dependencies:')[1]
        .split('dev_dependencies:')[0];

    expect(
      RegExp(r'^\s+feature_', multiLine: true).hasMatch(dependencies),
      isFalse,
    );
    expect(dependencies, isNot(contains('supabase_flutter:')));
    expect(dependencies, isNot(contains('go_router:')));
  });
}
