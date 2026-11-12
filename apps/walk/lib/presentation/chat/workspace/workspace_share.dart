import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';

import '../../lock/media_pick_guard.dart';

/// 작업 폴더 파일을 시스템 공유 시트로 내보낸다. 테스트는 가짜를 쓴다.
abstract interface class WorkspaceShare {
  /// [absolutePath] 는 `Workspace.absolutePath` 결과, [name] 은 받는 앱에 보일 이름.
  Future<void> share(String absolutePath, String name);
}

/// `share_plus` 구현. 공유 시트로 나가 있는 동안 [MediaPickGuard] 를 켜 돌아왔을 때
/// 일기가 다시 잠기지 않는다. 종류(MIME)는 플러그인이 확장자로 고른다.
/// 플러그인이라 단위 테스트는 하지 않는다.
@LazySingleton(as: WorkspaceShare)
class SharePlusWorkspaceShare implements WorkspaceShare {
  SharePlusWorkspaceShare(this._guard);

  final MediaPickGuard _guard;

  @override
  Future<void> share(String absolutePath, String name) => _guard.run(
    () => SharePlus.instance.share(
      ShareParams(files: [XFile(absolutePath, name: name)]),
    ),
  );
}
