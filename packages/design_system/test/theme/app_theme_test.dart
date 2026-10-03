import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('인자 없이 부르면 기존 시드로 만든다', () {
    final expected = ColorScheme.fromSeed(seedColor: AppColors.seed);
    expect(AppTheme.light().colorScheme.primary, expected.primary);
  });

  test('넘긴 시드가 scheme 에 반영된다', () {
    const seed = Color(0xFF1D9E75);
    final expected =
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    expect(AppTheme.dark(seedColor: seed).colorScheme.primary, expected.primary);
  });
}
