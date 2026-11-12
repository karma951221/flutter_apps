import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/chat/workspace/workspace.dart';
import 'workspace_state.dart';

/// 작업 폴더 화면. [load] 로 두 구역을 읽고, [delete] 는 지운 뒤 다시 읽는다.
class WorkspaceCubit extends Cubit<WorkspaceState> {
  WorkspaceCubit(this._workspace) : super(const WorkspaceState.loading());

  final Workspace _workspace;

  Future<void> load() async {
    try {
      final out = await _workspace.list(WorkspaceArea.out);
      final inbox = await _workspace.list(WorkspaceArea.inbox);
      if (isClosed) return;
      final all = [...out, ...inbox];
      emit(
        WorkspaceState.ready(
          out: out,
          inbox: inbox,
          totalCount: all.length,
          totalBytes: all.fold(0, (sum, f) => sum + f.sizeBytes),
        ),
      );
    } on Object {
      if (!isClosed) emit(const WorkspaceState.failure());
    }
  }

  /// 지우지 못하면 false — 목록은 그대로 두고 화면이 알린다.
  Future<bool> delete(WorkspaceFile file) async {
    try {
      await _workspace.delete(file.path);
    } on Object {
      return false;
    }
    await load();
    return true;
  }
}
