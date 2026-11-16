import 'dart:io';

/// [current] 를 [incoming] 폴더로 바꿔 넣고 [commit](DB 트랜잭션)을 부른다.
///
/// `current` → `current.old`, `incoming` → `current` 순으로 이름만 바꾼다. [commit] 이
/// 실패하면 두 폴더를 제자리로 돌리고 다시 던진다. 성공하면 `.old` 를 지운다.
/// [current] 가 없어도(새 기기) 동작한다.
Future<void> swapDirectory(
  Directory current,
  Directory incoming,
  Future<void> Function() commit,
) async {
  final old = Directory('${current.path}.old');
  // 지난번에 도중 종료로 남은 찌꺼기. 지금 폴더가 기준이다.
  if (await old.exists()) await old.delete(recursive: true);

  final hadCurrent = await current.exists();
  if (hadCurrent) await current.rename(old.path);
  try {
    await incoming.rename(current.path);
  } catch (_) {
    if (hadCurrent) await old.rename(current.path);
    rethrow;
  }

  try {
    await commit();
  } catch (_) {
    await current.rename(incoming.path);
    if (hadCurrent) await old.rename(current.path);
    rethrow;
  }

  if (hadCurrent) await old.delete(recursive: true);
}
