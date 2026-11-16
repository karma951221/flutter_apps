import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 백업 파일이 어떤 모양인지(첫 4바이트로 가른다).
enum BackupFileKind { zip, encrypted, unknown }

enum BackupCipherError { wrongPasswordOrCorrupt, notEncrypted }

class BackupCipherException implements Exception {
  const BackupCipherException(this.error);

  final BackupCipherError error;

  @override
  String toString() => 'BackupCipherException($error)';
}

const _magic = [0x4c, 0x4c, 0x42, 0x4b]; // "LLBK"
const _zipMagic = [0x50, 0x4b, 0x03, 0x04]; // "PK\x03\x04"
const _containerVersion = 1;
const _saltLen = 16;
const _noncePrefixLen = 8;
const _tagLen = 16;
const _chunkSize = 1024 * 1024;
// 매직 4 + 버전 1 + 반복 횟수 4 + salt 16 + nonce 접두 8
const _headerLen = 4 + 1 + 4 + _saltLen + _noncePrefixLen;

/// 파일 앞 4바이트로 zip · 암호화 백업 · 그 외를 가른다.
Future<BackupFileKind> sniffBackupFile(File f) async {
  final raf = await f.open();
  try {
    final head = await _readUpTo(raf, 4);
    if (_startsWith(head, _zipMagic)) return BackupFileKind.zip;
    if (_startsWith(head, _magic)) return BackupFileKind.encrypted;
    return BackupFileKind.unknown;
  } finally {
    await raf.close();
  }
}

/// 비밀번호로 백업 zip 을 덩어리(1 MiB)별 AES-256-GCM 으로 봉하고 푼다.
///
/// 덩어리마다 nonce = 접두 ‖ 덩어리 번호, AAD = 헤더 ‖ 번호 ‖ 마지막 여부라서
/// 덩어리를 바꾸거나 잘라내면 인증이 깨진다. 전체를 메모리에 올리지 않는다.
class BackupCipher {
  BackupCipher({this.iterations = 600000});

  /// 새로 봉할 때 쓸 PBKDF2 반복 횟수. 풀 때는 헤더 값을 쓴다.
  final int iterations;

  static final _aes = AesGcm.with256bits();
  static final _random = Random.secure();

  Future<void> encrypt(File plain, File out, String password) async {
    final header = BytesBuilder()
      ..add(_magic)
      ..addByte(_containerVersion)
      ..add(
        (ByteData(
          4,
        )..setUint32(0, iterations, Endian.big)).buffer.asUint8List(),
      )
      ..add(_randomBytes(_saltLen))
      ..add(_randomBytes(_noncePrefixLen));
    final headerBytes = header.toBytes();
    final key = await _deriveKey(password, headerBytes, iterations);
    final noncePrefix = headerBytes.sublist(_headerLen - _noncePrefixLen);

    final input = await plain.open();
    final output = await out.open(mode: FileMode.write);
    try {
      await output.writeFrom(headerBytes);
      var index = 0;
      var current = await _readUpTo(input, _chunkSize);
      while (true) {
        // 한 덩어리 앞서 읽어 지금 덩어리가 마지막인지 안다(빈 파일도 1덩어리).
        final next = current.length < _chunkSize
            ? Uint8List(0)
            : await _readUpTo(input, _chunkSize);
        final isLast = next.isEmpty;
        final box = await _aes.encrypt(
          current,
          secretKey: key,
          nonce: _nonce(noncePrefix, index),
          aad: _aad(headerBytes, index, isLast),
        );
        await output.writeFrom(box.cipherText);
        await output.writeFrom(box.mac.bytes);
        if (isLast) break;
        current = next;
        index++;
      }
    } finally {
      await input.close();
      await output.close();
    }
  }

  Future<void> decrypt(File sealed, File out, String password) async {
    final input = await sealed.open();
    RandomAccessFile? output;
    try {
      final headerBytes = await _readUpTo(input, _headerLen);
      if (!_startsWith(headerBytes, _magic)) {
        throw const BackupCipherException(BackupCipherError.notEncrypted);
      }
      if (headerBytes.length < _headerLen ||
          headerBytes[4] != _containerVersion) {
        throw const BackupCipherException(
          BackupCipherError.wrongPasswordOrCorrupt,
        );
      }
      final iter = ByteData.sublistView(
        headerBytes,
        5,
        9,
      ).getUint32(0, Endian.big);
      if (iter < 1) {
        throw const BackupCipherException(
          BackupCipherError.wrongPasswordOrCorrupt,
        );
      }
      final key = await _deriveKey(password, headerBytes, iter);
      final noncePrefix = headerBytes.sublist(_headerLen - _noncePrefixLen);

      output = await out.open(mode: FileMode.write);
      const sealedChunk = _chunkSize + _tagLen;
      var index = 0;
      var current = await _readUpTo(input, sealedChunk);
      while (true) {
        final next = current.length < sealedChunk
            ? Uint8List(0)
            : await _readUpTo(input, sealedChunk);
        final isLast = next.isEmpty;
        if (current.length < _tagLen) {
          throw const BackupCipherException(
            BackupCipherError.wrongPasswordOrCorrupt,
          );
        }
        final split = current.length - _tagLen;
        final List<int> plain;
        try {
          plain = await _aes.decrypt(
            SecretBox(
              Uint8List.sublistView(current, 0, split),
              nonce: _nonce(noncePrefix, index),
              mac: Mac(Uint8List.sublistView(current, split)),
            ),
            secretKey: key,
            aad: _aad(headerBytes, index, isLast),
          );
        } on SecretBoxAuthenticationError {
          throw const BackupCipherException(
            BackupCipherError.wrongPasswordOrCorrupt,
          );
        }
        await output.writeFrom(plain);
        if (isLast) break;
        current = next;
        index++;
      }
    } catch (_) {
      // 인증 실패 · 입출력 오류 모두 부분 출력은 남기지 않는다.
      await output?.close();
      output = null;
      if (out.existsSync()) out.deleteSync();
      rethrow;
    } finally {
      await input.close();
      await output?.close();
    }
  }

  Future<SecretKey> _deriveKey(
    String password,
    Uint8List header,
    int iterations,
  ) {
    final salt = header.sublist(9, 9 + _saltLen);
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
  }

  static Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List<int>.generate(n, (_) => _random.nextInt(256)));

  static Uint8List _nonce(List<int> prefix, int index) {
    final b = BytesBuilder()
      ..add(prefix)
      ..add(
        (ByteData(4)..setUint32(0, index, Endian.big)).buffer.asUint8List(),
      );
    return b.toBytes();
  }

  static Uint8List _aad(Uint8List header, int index, bool isLast) {
    final b = BytesBuilder()
      ..add(header)
      ..add((ByteData(4)..setUint32(0, index, Endian.big)).buffer.asUint8List())
      ..addByte(isLast ? 1 : 0);
    return b.toBytes();
  }
}

/// 파일 끝이 아니면 정확히 [n] 바이트를 읽는다(짧은 읽기를 이어 붙인다).
Future<Uint8List> _readUpTo(RandomAccessFile raf, int n) async {
  final b = BytesBuilder(copy: false);
  var left = n;
  while (left > 0) {
    final part = await raf.read(left);
    if (part.isEmpty) break;
    b.add(part);
    left -= part.length;
  }
  return b.toBytes();
}

bool _startsWith(Uint8List data, List<int> prefix) {
  if (data.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (data[i] != prefix[i]) return false;
  }
  return true;
}
