import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dogs_redirect.dart';

GoRouter createRouter({required bool hasDogs}) {
  final dogsRedirect = DogsRedirect(hasDogs: hasDogs);
  return GoRouter(
    initialLocation: PawlogPaths.feed,
    redirect: (_, state) => dogsRedirect.resolve(state.matchedLocation),
    routes: [
      GoRoute(
        path: PawlogPaths.feed,
        // TODO(phase ④~⑦): 산책 피드 페이지로 교체한다 (onStartWalk, onOpenWalk(id), onOpenDogs).
        builder: (context, _) => const _Placeholder(title: 'feed'),
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
        // TODO(phase ④~⑦): 반려견 목록 페이지로 교체한다.
        builder: (context, _) => const _Placeholder(title: 'dogs'),
        routes: [
          // `/dogs/new` 는 반드시 `/dogs/:id` 보다 먼저 선언한다.
          GoRoute(
            path: 'new',
            // TODO(phase ④~⑦): 반려견 등록 페이지로 교체한다 (onDone → markHasDogs + go feed).
            builder: (context, _) => const _Placeholder(title: 'new dog'),
          ),
          GoRoute(
            path: ':id',
            // TODO(phase ④~⑦): 반려견 상세 페이지로 교체한다.
            builder: (context, state) =>
                _Placeholder(title: 'dog ${state.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}
