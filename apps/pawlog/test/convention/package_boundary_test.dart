import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pawlog 앱은 Supabase 를 직접 쓰지만 트레이더 feature 패키지는 의존하지 않는다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final dependencies = pubspec
        .split('dependencies:')[1]
        .split('dev_dependencies:')[0];

    expect(
      RegExp(r'^\s+feature_', multiLine: true).hasMatch(dependencies),
      isFalse,
    );
    // W5 social: 모두의 산책 · 로그인은 pawlog 가 SupabaseClient 를 직접 쓴다(plan 결정 8).
    expect(dependencies, contains('supabase_flutter:'));
  });
}
