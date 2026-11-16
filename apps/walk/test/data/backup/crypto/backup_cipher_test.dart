import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/data/backup/crypto/backup_cipher.dart';

const _mib = 1024 * 1024;
// 헤더: 매직 4 + 버전 1 + 반복 횟수 4 + salt 16 + nonce 접두 8
const _headerLen = 33;
const _tagLen = 16;

Uint8List _bytes(int n) =>
    Uint8List.fromList(List<int>.generate(n, (i) => (i * 31 + 7) & 0xff));

void main() {
  late Directory dir;
  late BackupCipher cipher;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('backup_cipher_test');
    cipher = BackupCipher(iterations: 1000);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  File file(String name, [List<int>? data]) {
    final f = File('${dir.path}/$name');
    if (data != null) f.writeAsBytesSync(data);
    return f;
  }

  Future<File> seal(List<int> data, {String password = 'password-1'}) async {
    final plain = file('plain.bin', data);
    final sealed = file('sealed.bin');
    await cipher.encrypt(plain, sealed, password);
    return sealed;
  }

  Future<void> expectCorrupt(File sealed) async {
    await expectLater(
      cipher.decrypt(sealed, file('out.bin'), 'password-1'),
      throwsA(
        isA<BackupCipherException>().having(
          (e) => e.error,
          'error',
          BackupCipherError.wrongPasswordOrCorrupt,
        ),
      ),
    );
  }

  group('round trip', () {
    for (final n in [0, 1, _mib, 2 * _mib + _mib ~/ 2]) {
      test('$n B', () async {
        final data = _bytes(n);
        final sealed = await seal(data);
        final out = file('out.bin');
        await cipher.decrypt(sealed, out, 'password-1');
        expect(out.readAsBytesSync(), data);
      });
    }
  });

  test('wrong password fails with wrongPasswordOrCorrupt', () async {
    final sealed = await seal(_bytes(100));
    await expectLater(
      cipher.decrypt(sealed, file('out.bin'), 'other-password'),
      throwsA(
        isA<BackupCipherException>().having(
          (e) => e.error,
          'error',
          BackupCipherError.wrongPasswordOrCorrupt,
        ),
      ),
    );
  });

  test('flipped byte in second chunk fails', () async {
    final sealed = await seal(_bytes(2 * _mib + 10));
    final raw = sealed.readAsBytesSync();
    raw[_headerLen + (_mib + _tagLen) + 5] ^= 0x01;
    sealed.writeAsBytesSync(raw);
    await expectCorrupt(sealed);
  });

  test('truncated last chunk fails', () async {
    final sealed = await seal(_bytes(2 * _mib + 10));
    final raw = sealed.readAsBytesSync();
    sealed.writeAsBytesSync(raw.sublist(0, raw.length - 3));
    await expectCorrupt(sealed);
  });

  test('dropping whole last chunk fails', () async {
    final sealed = await seal(_bytes(2 * _mib + 10));
    final raw = sealed.readAsBytesSync();
    sealed.writeAsBytesSync(raw.sublist(0, _headerLen + 2 * (_mib + _tagLen)));
    await expectCorrupt(sealed);
  });

  test('swapped chunks fail', () async {
    final sealed = await seal(_bytes(3 * _mib));
    final raw = sealed.readAsBytesSync();
    const size = _mib + _tagLen;
    final a = raw.sublist(_headerLen, _headerLen + size);
    final b = raw.sublist(_headerLen + size, _headerLen + 2 * size);
    raw.setRange(_headerLen, _headerLen + size, b);
    raw.setRange(_headerLen + size, _headerLen + 2 * size, a);
    sealed.writeAsBytesSync(raw);
    await expectCorrupt(sealed);
  });

  test('header records iterations and salt; two encryptions differ', () async {
    final plain = file('plain.bin', _bytes(50));
    final a = file('a.bin');
    final b = file('b.bin');
    await cipher.encrypt(plain, a, 'password-1');
    await cipher.encrypt(plain, b, 'password-1');
    final ra = a.readAsBytesSync();
    final rb = b.readAsBytesSync();

    expect(String.fromCharCodes(ra.sublist(0, 4)), 'LLBK');
    expect(ra[4], 1);
    expect(ByteData.sublistView(ra, 5, 9).getUint32(0, Endian.big), 1000);
    expect(ra.sublist(9, 25), isNot(rb.sublist(9, 25))); // salt
    expect(ra, isNot(rb));
  });

  test('decrypt reads iterations from the header', () async {
    final sealed = await seal(_bytes(10));
    final out = file('out.bin');
    await BackupCipher(iterations: 5).decrypt(sealed, out, 'password-1');
    expect(out.readAsBytesSync(), _bytes(10));
  });

  test('plain zip is notEncrypted', () async {
    final zip = file('a.zip', [0x50, 0x4b, 3, 4, 0, 0, 0, 0, 0, 0]);
    await expectLater(
      cipher.decrypt(zip, file('out.bin'), 'password-1'),
      throwsA(
        isA<BackupCipherException>().having(
          (e) => e.error,
          'error',
          BackupCipherError.notEncrypted,
        ),
      ),
    );
  });

  group('sniffBackupFile', () {
    test('zip', () async {
      final f = file('a', [0x50, 0x4b, 3, 4, 1, 2]);
      expect(await sniffBackupFile(f), BackupFileKind.zip);
    });
    test('encrypted', () async {
      final f = await seal(_bytes(5));
      expect(await sniffBackupFile(f), BackupFileKind.encrypted);
    });
    test('unknown', () async {
      expect(
        await sniffBackupFile(file('a', [1, 2, 3])),
        BackupFileKind.unknown,
      );
      expect(await sniffBackupFile(file('b', [])), BackupFileKind.unknown);
    });
  });
}
