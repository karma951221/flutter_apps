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

  group('splash_icon (windowSplashScreenAnimatedIcon 규격)', () {
    // 288dp 캔버스 중 가운데 지름 192dp 원 안에 그린다. 레이어 리스트로 108dp 벡터를
    // 감싸면 API 31+ 시스템 스플래시가 크기를 무시하고 확대 · 잘라 그린다(QA s1).
    final icon = _read('drawable/splash_icon.xml');

    double attr(String source, String name) => double.parse(
      RegExp('android:$name="([-0-9.]+)"').firstMatch(source)!.group(1)!,
    );

    test('레이어 리스트가 아닌 288 뷰포트 벡터 하나다', () {
      expect(icon, isNot(contains('<layer-list')));
      expect(icon, contains('<vector'));
      expect(icon, contains('android:width="288dp"'));
      expect(icon, contains('android:height="288dp"'));
      expect(attr(icon, 'viewportWidth'), 288);
      expect(attr(icon, 'viewportHeight'), 288);
    });

    test('전경 경로를 그대로 옮기고 안전 원(108 중 반지름 33)을 가운데 192 원 안에 둔다', () {
      final foreground = _read('drawable/ic_launcher_foreground.xml');
      List<String> paths(String source) => RegExp(
        r'android:pathData="([^"]+)"',
      ).allMatches(source).map((m) => m.group(1)!).toList();

      expect(paths(icon), paths(foreground));

      final scaleX = attr(icon, 'scaleX');
      final scaleY = attr(icon, 'scaleY');
      final translateX = attr(icon, 'translateX');
      final translateY = attr(icon, 'translateY');
      expect(scaleX, scaleY);
      // 전경 중심 (54,54) → 캔버스 중심 (144,144)
      expect(54 * scaleX + translateX, closeTo(144, 0.01));
      expect(54 * scaleY + translateY, closeTo(144, 0.01));
      // 안전 원 반지름 33 이 지름 192 원(반지름 96) 안
      expect(33 * scaleX, lessThanOrEqualTo(96));
      expect(33 * scaleX, greaterThan(80));
    });
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
