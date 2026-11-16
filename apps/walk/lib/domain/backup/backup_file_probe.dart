import 'dart:io';

/// 고른 파일을 열기 전에 비밀번호가 필요한지 본다(첫 4바이트).
abstract interface class BackupFileProbe {
  /// 비밀번호로 잠근 백업(`LLBK`)이면 true. zip · 모르는 파일은 false — 검사가 가른다.
  Future<bool> isEncrypted(File file);
}
