import 'package:feature_walk/feature_walk.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dogs_redirect.dart';

GoRouter createRouter({required bool hasDogs}) {
  final dogsRedirect = DogsRedirect(hasDogs: hasDogs);

  /// 반려견 저장 · 삭제 뒤: 되돌아갈 곳이 있으면 pop, 첫 실행이면 피드로 간다.
  void finishDogEdit(BuildContext context) {
    dogsRedirect.markHasDogs();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PawlogPaths.feed);
    }
  }

  return GoRouter(
    initialLocation: PawlogPaths.feed,
    redirect: (_, state) => dogsRedirect.resolve(state.matchedLocation),
    routes: [
      GoRoute(
        path: PawlogPaths.feed,
        // TODO(phase ④~⑦): 산책 피드 페이지로 교체한다 (onStartWalk, onOpenWalk(id), onOpenDogs).
        builder: (context, _) => _Placeholder(
          title: 'feed',
          onStartWalk: () => context.push(PawlogPaths.activeWalk),
          onOpenDogs: () => context.push(PawlogPaths.dogs),
        ),
      ),
      GoRoute(
        path: PawlogPaths.activeWalk,
        builder: (context, _) => ActiveWalkPage(
          // go 는 최상위 경로라 피드가 스택에서 사라져 뒤로 가기가 앱을 닫는다.
          // 진행 화면만 저장 폼으로 바꿔 끼운다 (⑤ 리뷰 V1).
          onStopped: () => context.pushReplacement(PawlogPaths.saveWalk),
          onOpenDogs: () => context.push(PawlogPaths.dogs),
        ),
      ),
      GoRoute(
        path: PawlogPaths.saveWalk,
        builder: (context, _) => WalkEditPage(
          // 스택이 피드 → 상세가 되도록 먼저 피드로 간 뒤 상세를 올린다.
          onSaved: (id) {
            context.go(PawlogPaths.feed);
            context.push(PawlogPaths.walk(id));
          },
          onDiscarded: () => context.go(PawlogPaths.feed),
        ),
      ),
      GoRoute(
        path: PawlogPaths.walks,
        // 산책 목록은 피드와 겹친다. 하위 `:id` 는 이 redirect 를 받지 않게 목록 경로만 돌린다.
        redirect: (_, state) => state.matchedLocation == PawlogPaths.walks
            ? PawlogPaths.feed
            : null,
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => WalkDetailPage(
              walkId: state.pathParameters['id']!,
              // 수정에서 돌아오면 상세가 스스로 다시 읽는다.
              onEdit: (id) async {
                await context.push(PawlogPaths.walkEdit(id));
              },
              onDeleted: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(PawlogPaths.feed);
                }
              },
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => WalkEditPage(
                  walkId: state.pathParameters['id'],
                  onSaved: (_) => context.pop(),
                  onDiscarded: () => context.pop(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: PawlogPaths.dogs,
        builder: (context, _) => DogListPage(
          onAddDog: () => context.push(PawlogPaths.newDog),
          onOpenDog: (id) => context.push(PawlogPaths.dog(id)),
        ),
        routes: [
          // `/dogs/new` 는 반드시 `/dogs/:id` 보다 먼저 선언한다.
          GoRoute(
            path: 'new',
            builder: (context, _) =>
                DogEditPage(onDone: () => finishDogEdit(context)),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => DogEditPage(
              dogId: state.pathParameters['id'],
              onDone: () => finishDogEdit(context),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, this.onStartWalk, this.onOpenDogs});

  final String title;

  /// 피드가 서기 전까지 진행 화면에 닿는 임시 진입점.
  final VoidCallback? onStartWalk;

  /// 피드가 서기 전까지 반려견 화면에 닿는 임시 진입점.
  final VoidCallback? onOpenDogs;

  @override
  Widget build(BuildContext context) {
    final onStartWalk = this.onStartWalk;
    final onOpenDogs = this.onOpenDogs;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (onStartWalk != null)
              TextButton(onPressed: onStartWalk, child: const Text('walk')),
            if (onOpenDogs != null)
              TextButton(onPressed: onOpenDogs, child: const Text('dogs')),
          ],
        ),
      ),
    );
  }
}
