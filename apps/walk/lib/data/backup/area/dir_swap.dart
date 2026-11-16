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

/// 내보낼 때 영역의 파일 폴더(`diary/media` · `chat/workspace` · `alarm/sounds`)에 두는 빈 표시
/// 파일. zip 은 빈 폴더를 담지 않으므로 "파일 없는 폴더가 있었다"를 이것으로 남긴다 —
/// [replaceFilesFolder] 는 폴더가 없으면 이미 옮겨 간 것으로 본다.
const filesFolderMarker = '.lifelog-folder';

/// 영역 `export` 가 파일 폴더 [dir] 을 만들고 표시를 둔다.
Future<void> createFilesFolder(Directory dir) async {
  await dir.create(recursive: true);
  await File('${dir.path}/$filesFolderMarker').writeAsString('');
}

/// [incoming] 의 표시를 지운다. 지금 폴더로 옮겨 가지 않게 [replaceFilesFolder] 전에 부른다.
Future<void> dropFilesFolderMarker(Directory incoming) async {
  final marker = File('${incoming.path}/$filesFolderMarker');
  if (await marker.exists()) await marker.delete();
}

/// 영역 `replace` 의 파일 폴더 부분.
///
/// [incoming] 이 있으면 표시를 지우고 [swapDirectory] 로 바꿔 넣는다. 없으면 지난번 같은
/// `replace` 가 이미 옮겨 간 것이다(옮긴 뒤 · 되돌리기 폴더를 지우기 전에 죽어 시작 때 다시
/// 돌림) — 그때 [current] 가 옮겨 온 파일이므로 그대로 두고 [commit](DB)만 한다. 빈 폴더로
/// 바꿔 넣으면 그 파일을 지우게 된다.
Future<void> replaceFilesFolder(
  Directory current,
  Directory incoming,
  Future<void> Function() commit,
) async {
  if (!await incoming.exists()) {
    await commit();
    // 도중 종료로 남은 바꾸기 전 폴더. 지금 폴더가 기준이다.
    final old = Directory('${current.path}.old');
    if (await old.exists()) await old.delete(recursive: true);
    return;
  }
  await dropFilesFolderMarker(incoming);
  await current.parent.create(recursive: true);
  await swapDirectory(current, incoming, commit);
}
