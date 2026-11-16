import 'dart:io';

/// 백업 파일을 기기 밖 위치로 저장하고, 고른 백업 파일을 앱으로 가져오고, 복원 뒤 앱을 다시 띄운다.
/// 실패는 `BackupException(BackupFailure.noSpace | io)`.
abstract interface class BackupFiles {
  /// "저장 위치 고르기"로 [source] 를 [suggestedName] 으로 저장한다. 사용자가 취소하면 false.
  Future<bool> saveAs(File source, String suggestedName);

  /// 문서 고르기 창에서 고른 파일의 앱 캐시 사본. 취소하면 null. 다 쓰면 호출한 쪽이 지운다.
  Future<File?> open();

  /// 복원한 데이터로 처음부터 시작하도록 앱을 다시 띄운다.
  Future<void> restartApp();

  /// 앱 데이터가 있는 저장소의 여유 바이트(백업 만들기 · 검사 전 공간 검사). 읽지 못하면 null —
  /// 검사를 건너뛴다. 던지지 않는다.
  Future<int?> freeBytes();
}
