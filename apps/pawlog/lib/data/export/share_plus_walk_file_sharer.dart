import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/export/repository/walk_file_sharer.dart';

/// 임시 파일은 OS 캐시 디렉터리에 쓰고 같은 이름이면 덮어쓴다.
/// iPad 는 공유 시트에 `sharePositionOrigin` 이 필요하지만 iOS 가 아직 검증 전이라
/// pawlog 는 넘기지 않는다(docs/status.md 의 iOS 미검증 메모 참고).
@LazySingleton(as: WalkFileSharer)
class SharePlusWalkFileSharer implements WalkFileSharer {
  @override
  Future<Result<void>> shareFile({
    required String fileName,
    required String contents,
    required String mimeType,
  }) => _share(fileName, mimeType, (file) => file.writeAsString(contents));

  @override
  Future<Result<void>> shareBytes({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) => _share(fileName, mimeType, (file) => file.writeAsBytes(bytes));

  Future<Result<void>> _share(
    String fileName,
    String mimeType,
    Future<File> Function(File file) write,
  ) async {
    try {
      final temp = await getTemporaryDirectory();
      final dir = Directory(p.join(temp.path, 'pawlog_export'));
      await dir.create(recursive: true);
      final path = p.join(dir.path, fileName);
      await write(File(path));
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: mimeType)]),
      );
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }
}
