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

  test('walk 앱은 일기 위치 태그에 workspace location 패키지를 의존한다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = pubspec
        .split('dependencies:')[1]
        .split('dev_dependencies:')[0];

    expect(
      RegExp(r'^  location: any$', multiLine: true).hasMatch(dependencies),
      isTrue,
    );
  });

  test('alarm 은 third_party 포크를 path 의존성으로 쓴다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      RegExp(
        r'^  alarm:\n    path: third_party/alarm$',
        multiLine: true,
      ).hasMatch(pubspec),
      isTrue,
    );
    expect(File('third_party/alarm/FORK.md').existsSync(), isTrue);
    expect(File('third_party/alarm/LICENSE').existsSync(), isTrue);
  });

  test('alarm 포크는 루트 workspace 멤버가 아니다', () {
    final rootPubspec = File('../../pubspec.yaml').readAsStringSync();
    final forkPubspec = File(
      'third_party/alarm/pubspec.yaml',
    ).readAsStringSync();

    expect(rootPubspec, isNot(contains('third_party')));
    expect(forkPubspec, isNot(contains('resolution: workspace')));
  });
}
