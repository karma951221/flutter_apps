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
          onOpenDogs: () => context.push(PawlogPaths.dogs),
        ),
      ),
      GoRoute(
        path: PawlogPaths.activeWalk,
        // TODO(phase ④~⑦): 산책 진행 페이지로 교체한다.
        builder: (context, _) => const _Placeholder(title: 'active walk'),
      ),
      GoRoute(
        path: PawlogPaths.saveWalk,
        // TODO(phase ④~⑦): 산책 저장 페이지로 교체한다 (onDone).
        builder: (context, _) => const _Placeholder(title: 'save walk'),
      ),
      GoRoute(
        path: PawlogPaths.walks,
        // TODO(phase ④~⑦): 산책 목록 페이지로 교체한다 (onOpenWalk(id)).
        builder: (context, _) => const _Placeholder(title: 'walks'),
        routes: [
          GoRoute(
            path: ':id',
            // TODO(phase ④~⑦): 산책 상세 페이지로 교체한다.
            builder: (context, state) =>
                _Placeholder(title: 'walk ${state.pathParameters['id']}'),
            routes: [
              GoRoute(
                path: 'edit',
                // TODO(phase ④~⑦): 산책 수정 페이지로 교체한다.
                builder: (context, state) => _Placeholder(
                  title: 'edit walk ${state.pathParameters['id']}',
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
  const _Placeholder({required this.title, this.onOpenDogs});

  final String title;

  /// 피드가 서기 전까지 반려견 화면에 닿는 임시 진입점.
  final VoidCallback? onOpenDogs;

  @override
  Widget build(BuildContext context) {
    final onOpenDogs = this.onOpenDogs;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (onOpenDogs != null)
              TextButton(onPressed: onOpenDogs, child: const Text('dogs')),
          ],
        ),
      ),
    );
  }
}
