/// 백업 설정. 마지막으로 백업 파일을 만든 시각을 기억한다.
abstract interface class BackupPreferences {
  /// 마지막 내보내기 성공 시각. 없거나 읽을 수 없으면 null.
  DateTime? get lastAt;

  Future<void> setLastAt(DateTime at);
}
