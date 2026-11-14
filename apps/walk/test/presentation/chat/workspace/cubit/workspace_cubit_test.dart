import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/chat/workspace/workspace_changes.dart';
import 'package:walk/presentation/chat/workspace/cubit/workspace_cubit.dart';
import 'package:walk/presentation/chat/workspace/cubit/workspace_state.dart';

import '../workspace_fakes.dart';

void main() {
  final bytes = Uint8List.fromList([1]);
  final out = workspaceFile('out/20261113-1405-a.md', sizeBytes: 100);
  final inboxOld = workspaceFile(
    'inbox/20261112-090000-b.pdf',
    sizeBytes: 2000,
    modifiedAt: DateTime(2026, 11, 12, 9),
  );
  final inboxNew = workspaceFile(
    'inbox/20261113-100000-c.jpg',
    sizeBytes: 300,
    modifiedAt: DateTime(2026, 11, 13, 10),
  );

  test('처음은 loading, load 하면 두 구역(최신순) · 개수 · 바이트 합', () async {
    final ws = MemoryWorkspace([
      (out, bytes),
      (inboxOld, bytes),
      (inboxNew, bytes),
    ]);
    final cubit = WorkspaceCubit(ws);
    addTearDown(cubit.close);
    expect(cubit.state, const WorkspaceState.loading());

    await cubit.load();

    expect(
      cubit.state,
      WorkspaceState.ready(
        out: [out],
        inbox: [inboxNew, inboxOld],
        totalCount: 3,
        totalBytes: 2400,
      ),
    );
  });

  test('목록을 읽지 못하면 failure', () async {
    final ws = MemoryWorkspace([(out, bytes)])..failList = true;
    final cubit = WorkspaceCubit(ws);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state, const WorkspaceState.failure());
  });

  test('delete 는 그 경로를 지우고 목록을 다시 읽는다', () async {
    final ws = MemoryWorkspace([(out, bytes), (inboxOld, bytes)]);
    final cubit = WorkspaceCubit(ws);
    addTearDown(cubit.close);
    await cubit.load();

    expect(await cubit.delete(out), isTrue);

    expect(ws.deleted, [out.path]);
    expect(
      cubit.state,
      WorkspaceState.ready(
        out: const [],
        inbox: [inboxOld],
        totalCount: 1,
        totalBytes: 2000,
      ),
    );
  });

  test('지우지 못하면 false, 목록은 그대로', () async {
    final ws = MemoryWorkspace([(out, bytes)]);
    final cubit = WorkspaceCubit(ws);
    addTearDown(cubit.close);
    await cubit.load();
    final before = cubit.state;
    ws.failDelete = true;

    expect(await cubit.delete(out), isFalse);
    expect(cubit.state, before);
  });

  test('쓰기 신호가 오면 목록을 다시 읽는다', () async {
    final ws = MemoryWorkspace([(inboxOld, bytes)]);
    final changes = WorkspaceChanges();
    final cubit = WorkspaceCubit(ws, changes: changes);
    addTearDown(cubit.close);
    await cubit.load();

    ws.add(out, bytes);
    changes.notify();
    await pumpEventQueue();

    expect(
      cubit.state,
      WorkspaceState.ready(
        out: [out],
        inbox: [inboxOld],
        totalCount: 2,
        totalBytes: 2100,
      ),
    );
  });

  test('닫은 뒤의 신호는 무시한다', () async {
    final ws = MemoryWorkspace([(inboxOld, bytes)]);
    final changes = WorkspaceChanges();
    final cubit = WorkspaceCubit(ws, changes: changes);
    await cubit.load();
    await cubit.close();

    changes.notify();
    await pumpEventQueue();

    expect(cubit.isClosed, isTrue);
  });
}
