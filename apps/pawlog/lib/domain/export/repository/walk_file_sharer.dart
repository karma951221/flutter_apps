import 'package:core/core.dart';

/// 만든 파일을 OS 공유 시트로 넘기는 경계. 구현은 플랫폼 플러그인에 의존한다.
abstract interface class WalkFileSharer {
  Future<Result<void>> shareFile({
    required String fileName,
    required String contents,
    required String mimeType,
  });
}
