import 'dart:io';

import 'package:core/core.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/export/repository/walk_file_sharer.dart';

@LazySingleton(as: WalkFileSharer)
class SharePlusWalkFileSharer implements WalkFileSharer {
  @override
  Future<Result<void>> shareFile({
    required String fileName,
    required String contents,
    required String mimeType,
  }) async {
    try {
      final temp = await getTemporaryDirectory();
      final dir = Directory(p.join(temp.path, 'pawlog_export'));
      await dir.create(recursive: true);
      final path = p.join(dir.path, fileName);
      await File(path).writeAsString(contents);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: mimeType)]),
      );
      return const Ok(null);
    } catch (error) {
      return Err(Failure.unknown(message: error.toString()));
    }
  }
}
