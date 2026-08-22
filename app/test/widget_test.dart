import 'package:daylog/design_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 0단계 자리표시 테스트.
// 실제 테스트는 각 feature 의 test-cases.md 를 따라 1단계부터 작성한다.
void main() {
  test('테마가 light / dark 모두 생성된다', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });
}
