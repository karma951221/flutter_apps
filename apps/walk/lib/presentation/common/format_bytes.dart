/// 바이트 수를 사람이 읽는 크기로. 1024 단위. B · KB 는 정수, MB 부터 소수점 한 자리("1.2GB").
String formatBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)}GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)}MB';
  if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)}KB';
  return '${bytes}B';
}
