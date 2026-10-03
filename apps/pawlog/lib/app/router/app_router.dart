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
        builder: (context, _) => WalkFeedPage(
          onStartWalk: () => context.push(PawlogPaths.activeWalk),
          onSaveWalk: () => context.push(PawlogPaths.saveWalk),
          onOpenWalk: (id) => context.push(PawlogPaths.walk(id)),
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
        // 부모 경로의 redirect 안에서 `matchedLocation` 은 자식으로 가는 중에도 부모 경로라
        // 상세 · 수정까지 피드로 튕겼다 (⑥ 리뷰 W1). 실제 요청 경로로 비교한다.
        redirect: (_, state) =>
            state.uri.path == PawlogPaths.walks ? PawlogPaths.feed : null,
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
