import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 시작 화면(스플래시) 안드로이드 리소스가 서로 맞물리는지 본다.
/// 스펙: docs/superpowers/specs/2026-10-05-walk-app-face-design.md §2 · §3
const _res = 'android/app/src/main/res';

String _read(String path) => File('$_res/$path').readAsStringSync();

String _launchTheme(String styles) {
  final match = RegExp(
    r'<style name="LaunchTheme"[^>]*>(.*?)</style>',
    dotAll: true,
  ).firstMatch(styles);
  expect(match, isNotNull, reason: 'LaunchTheme 이 없다');
  return match!.group(1)!;
}

void main() {
  test('스플래시 배경 색은 라이트 #1D9E75 · 다크 #0F6E56 이다', () {
    final colors = _read('values/colors.xml');

    expect(colors, contains('<color name="splash_background">#1D9E75</color>'));
    expect(
      colors,
      contains('<color name="splash_background_dark">#0F6E56</color>'),
    );
  });

  test('splash_icon 은 전경 그림을 288dp 로 그린다', () {
    final icon = _read('drawable/splash_icon.xml');

    expect(icon, contains('@drawable/ic_launcher_foreground'));
    expect(icon, contains('android:width="288dp"'));
    expect(icon, contains('android:height="288dp"'));
  });

  group('안드로이드 12 이상 시스템 스플래시', () {
    for (final (dir, background) in [
      ('values-v31', '@color/splash_background'),
      ('values-night-v31', '@color/splash_background_dark'),
    ]) {
      test('$dir LaunchTheme 은 $background 배경 + splash_icon', () {
        final theme = _launchTheme(_read('$dir/styles.xml'));

        expect(
          theme,
          contains(
            '<item name="android:windowSplashScreenBackground">'
            '$background</item>',
          ),
        );
        expect(
          theme,
          contains(
            '<item name="android:windowSplashScreenAnimatedIcon">'
            '@drawable/splash_icon</item>',
          ),
        );
        expect(theme, isNot(contains('windowSplashScreenIconBackgroundColor')));
        expect(
          theme,
          contains(
            '<item name="android:windowBackground">'
            '@drawable/launch_background</item>',
          ),
        );
      });
    }
  });

  group('안드로이드 12 미만 launch_background', () {
    for (final (dir, background) in [
      ('drawable', '@color/splash_background'),
      ('drawable-v21', '@color/splash_background'),
      ('drawable-night', '@color/splash_background_dark'),
    ]) {
      test('$dir 는 $background 바탕 가운데 splash_icon', () {
        final layers = _read('$dir/launch_background.xml');

        expect(layers, contains('<item android:drawable="$background" />'));
        expect(
          RegExp(
            r'<item\s+android:drawable="@drawable/splash_icon"\s+'
            r'android:gravity="center"\s*/>',
          ).hasMatch(layers),
          isTrue,
        );
      });
    }
  });

  test('NormalTheme 은 깜빡임 없이 ?android:colorBackground 를 유지한다', () {
    for (final dir in ['values', 'values-night']) {
      final styles = _read('$dir/styles.xml');
      final normal = RegExp(
        r'<style name="NormalTheme"[^>]*>(.*?)</style>',
        dotAll: true,
      ).firstMatch(styles)!.group(1)!;

      expect(
        normal,
        contains(
          '<item name="android:windowBackground">?android:colorBackground</item>',
        ),
      );
    }
  });
}
