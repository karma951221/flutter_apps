import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/core/config/app_version.dart';

void main() {
  test('appVersion matches pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);

    expect(appVersion, version);
  });
}
