import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/backup/area/prefs_snapshot.dart';
import 'package:walk/domain/backup/backup_failure.dart';

const _keys = {'b', 'i', 'd', 's', 'l'};

const _values = <String, Object>{
  'b': true,
  'i': 3,
  'd': 2.0,
  's': '글',
  'l': ['x', 'y'],
};

Future<BackupFailure?> _failureOf(Future<void> Function() body) async {
  try {
    await body();
  } on BackupException catch (e) {
    return e.failure;
  }
  return null;
}

void main() {
  test('dumpPrefs writes only listed keys with their type', () async {
    SharedPreferences.setMockInitialValues({..._values, 'secret': 'k'});
    final prefs = await SharedPreferences.getInstance();

    expect(await dumpPrefs(prefs, _keys), {
      'b': {'type': 'bool', 'value': true},
      'i': {'type': 'int', 'value': 3},
      'd': {'type': 'double', 'value': 2.0},
      's': {'type': 'string', 'value': '글'},
      'l': {
        'type': 'stringList',
        'value': ['x', 'y'],
      },
    });
  });

  test(
    'round trip keeps every type (int stays int, double stays double)',
    () async {
      SharedPreferences.setMockInitialValues(_values);
      final dumped = await dumpPrefs(
        await SharedPreferences.getInstance(),
        _keys,
      );

      SharedPreferences.setMockInitialValues({'other': 1});
      final prefs = await SharedPreferences.getInstance();
      await restorePrefs(prefs, _keys, dumped);

      expect(prefs.get('i'), isA<int>());
      expect(prefs.get('d'), isA<double>());
      for (final e in _values.entries) {
        expect(prefs.get(e.key), e.value, reason: e.key);
      }
      expect(prefs.get('other'), 1);
    },
  );

  test('restorePrefs removes allowlisted keys absent from backup', () async {
    SharedPreferences.setMockInitialValues({..._values, 'other': 1});
    final prefs = await SharedPreferences.getInstance();

    await restorePrefs(prefs, _keys, {
      's': {'type': 'string', 'value': '새'},
    });

    expect(prefs.get('s'), '새');
    for (final key in _keys.difference({'s'})) {
      expect(prefs.containsKey(key), isFalse, reason: key);
    }
    expect(prefs.get('other'), 1);
  });

  test('restorePrefs ignores keys outside the allowlist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await restorePrefs(prefs, _keys, {
      'chat.apiKey': {'type': 'string', 'value': 'sk-…'},
    });

    expect(prefs.getKeys(), isEmpty);
  });

  test(
    'restorePrefs rejects a malformed entry before writing anything',
    () async {
      SharedPreferences.setMockInitialValues({'s': '그대로'});
      final prefs = await SharedPreferences.getInstance();

      for (final bad in <Object?>[
        'plain',
        {'type': 'int', 'value': 'x'},
        {'type': 'blob', 'value': 1},
        {
          'type': 'stringList',
          'value': [1],
        },
      ]) {
        expect(
          await _failureOf(
            () => restorePrefs(prefs, _keys, {
              'b': {'type': 'bool', 'value': false},
              'i': bad,
            }),
          ),
          BackupFailure.integrity,
          reason: '$bad',
        );
        expect(prefs.get('s'), '그대로');
        expect(prefs.containsKey('b'), isFalse);
      }
    },
  );

  group('prefs file', () {
    late Directory dir;

    setUp(
      () => dir = Directory.systemTemp.createTempSync('prefs_snapshot_test'),
    );
    tearDown(() => dir.deleteSync(recursive: true));

    test('missing file reads as empty, malformed file is integrity', () async {
      expect(await readPrefsSnapshot(dir, 'prefs.json', _keys), isEmpty);

      File('${dir.path}/prefs.json').writeAsStringSync('{oops');
      expect(
        await _failureOf(() => readPrefsSnapshot(dir, 'prefs.json', _keys)),
        BackupFailure.integrity,
      );

      File(
        '${dir.path}/prefs.json',
      ).writeAsStringSync('{"i":{"type":"int","value":"x"}}');
      expect(
        await _failureOf(() => readPrefsSnapshot(dir, 'prefs.json', _keys)),
        BackupFailure.integrity,
      );
    });
  });
}
